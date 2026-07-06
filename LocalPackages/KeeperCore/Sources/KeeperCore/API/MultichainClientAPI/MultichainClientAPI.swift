import Foundation
import MultichainAPI
import OpenAPIRuntime

public enum MultichainClientAPIError: Error {
    case cancelled
    case connectionError
    case badResponse(underlying: Error?)
    case badStatus(message: String)
    case undocumented(statusCode: Int)
}

protocol MultichainClientAPI {
    func healthcheck() async throws(MultichainClientAPIError) -> MultichainHealth
    func getNodes(ifNoneMatch: String?) async throws(MultichainClientAPIError) -> MultichainNodesResponse
    func searchAssets(
        currencies: [String],
        chain: MultichainChain?,
        search: String?,
        sort: MultichainAssetSearchSort,
        limit: Int?,
        cursor: String?
    ) async throws(MultichainClientAPIError) -> (assets: [MultichainAsset], nextCursor: String?)
    func getWallet(walletId: String) async throws(MultichainClientAPIError) -> MultichainRegisteredWallet
    func getWalletAssets(
        walletId: String,
        currencies: [String],
        chain: MultichainChain?,
        search: String?,
        availableOnly: Bool?,
        showHidden: Bool?,
        limit: Int?,
        cursor: String?
    ) async throws(MultichainClientAPIError) -> MultichainWalletAssetsPage
    func saveWalletAssetsFilters(walletId: String, changes: [MultichainAssetFilterChange]) async throws(MultichainClientAPIError)
    func getWalletActivities(
        walletId: String,
        limit: Int?,
        cursor: String?,
        chain: MultichainChain?,
        activityType: MultichainActivityType?
    ) async throws(MultichainClientAPIError) -> MultichainWalletActivitiesPage
    func registerWallet(walletId: String, addresses: [MultichainWalletAddress]) async throws(MultichainClientAPIError) -> MultichainRegisteredWallet
    func broadcastTx(chain: MultichainChain, signedTransaction: Data) async throws(MultichainClientAPIError) -> MultichainBroadcastResult
    func getFees(chain: MultichainChain) async throws(MultichainClientAPIError) -> MultichainFeeEstimate
}

final class MultichainClientAPIImplementation: MultichainClientAPI {
    let multichainAPIClient: MultichainAPI.Client

    init(multichainAPIClient: MultichainAPI.Client) {
        self.multichainAPIClient = multichainAPIClient
    }

    func healthcheck() async throws(MultichainClientAPIError) -> MultichainHealth {
        let output = try await apiCall(await multichainAPIClient.healthcheck())
        switch output {
        case let .ok(ok):
            let body = try decodeResponse(ok.body.json)
            return MultichainHealth(ok: body.ok)
        case let .internalServerError(error):
            throw try internalError(from: error)
        case let .undocumented(statusCode, _):
            throw MultichainClientAPIError.undocumented(statusCode: statusCode)
        }
    }

    func getNodes(ifNoneMatch: String?) async throws(MultichainClientAPIError) -> MultichainNodesResponse {
        let headers = MultichainAPI.Operations.getNodes.Input.Headers(
            If_hyphen_None_hyphen_Match: ifNoneMatch
        )
        let output = try await apiCall(await multichainAPIClient.getNodes(headers: headers))
        switch output {
        case let .ok(chainNodes):
            let nodes = try decodeResponse(chainNodes.body.json.nodes.map { MultichainNode(api: $0) })
            return .full(nodes: nodes, eTag: chainNodes.headers.ETag)
        case .notModified:
            return .notModified
        case let .internalServerError(error):
            throw try internalError(from: error)
        case let .undocumented(statusCode, _):
            throw MultichainClientAPIError.undocumented(statusCode: statusCode)
        }
    }

    func searchAssets(
        currencies: [String],
        chain: MultichainChain?,
        search: String?,
        sort: MultichainAssetSearchSort,
        limit: Int?,
        cursor: String?
    ) async throws(MultichainClientAPIError) -> (assets: [MultichainAsset], nextCursor: String?) {
        let query = MultichainAPI.Operations.searchAssets.Input.Query(
            chain: chain.map { $0.toAPISchemaChain() },
            currencies: currencies,
            search: search,
            sort: sort.toAPIParametersSort(),
            limit: limit,
            cursor: cursor
        )
        let output = try await apiCall(await multichainAPIClient.searchAssets(query: query))
        return try mapSearchAssetsOutput(output)
    }

    func getWallet(walletId: String) async throws(MultichainClientAPIError) -> MultichainRegisteredWallet {
        let path = MultichainAPI.Operations.getWallet.Input.Path(wallet_id: walletId)
        let output = try await apiCall(await multichainAPIClient.getWallet(path: path))
        switch output {
        case let .ok(response):
            let wallet = try decodeResponse(response.body.json)
            return MultichainRegisteredWallet(api: wallet)
        case let .badRequest(error):
            throw try badRequest(from: error)
        case let .notFound(error):
            throw try notFound(from: error)
        case let .internalServerError(error):
            throw try internalError(from: error)
        case let .undocumented(statusCode, _):
            throw MultichainClientAPIError.undocumented(statusCode: statusCode)
        }
    }

    func getWalletAssets(
        walletId: String,
        currencies: [String],
        chain: MultichainChain?,
        search: String?,
        availableOnly: Bool?,
        showHidden: Bool?,
        limit: Int?,
        cursor: String?
    ) async throws(MultichainClientAPIError) -> MultichainWalletAssetsPage {
        let path = MultichainAPI.Operations.getWalletAssets.Input.Path(wallet_id: walletId)
        let query = MultichainAPI.Operations.getWalletAssets.Input.Query(
            chain: chain.map { $0.toAPISchemaChain() },
            search: search,
            available_only: availableOnly,
            show_hidden: showHidden,
            currencies: currencies,
            limit: limit,
            cursor: cursor
        )
        let output = try await apiCall(await multichainAPIClient.getWalletAssets(path: path, query: query))
        return try mapWalletAssetsOutput(output)
    }

    func saveWalletAssetsFilters(walletId: String, changes: [MultichainAssetFilterChange]) async throws(MultichainClientAPIError) {
        let path = MultichainAPI.Operations.saveWalletAssetsFilters.Input.Path(wallet_id: walletId)
        let body = MultichainAPI.Components.RequestBodies.SetAssetFilters.json(
            .init(
                changes: changes.map {
                    .init(
                        asset_id: $0.assetId,
                        action: $0.action.toAPIRequestAction()
                    )
                }
            )
        )
        let output = try await apiCall(await multichainAPIClient.saveWalletAssetsFilters(path: path, body: body))
        switch output {
        case .ok:
            return
        case let .badRequest(error):
            throw try badRequest(from: error)
        case let .notFound(error):
            throw try notFound(from: error)
        case let .internalServerError(error):
            throw try internalError(from: error)
        case let .undocumented(statusCode, _):
            throw MultichainClientAPIError.undocumented(statusCode: statusCode)
        }
    }

    func getWalletActivities(
        walletId: String,
        limit: Int?,
        cursor: String?,
        chain: MultichainChain?,
        activityType: MultichainActivityType?
    ) async throws(MultichainClientAPIError) -> MultichainWalletActivitiesPage {
        let path = MultichainAPI.Operations.getWalletActivities.Input.Path(wallet_id: walletId)
        let query = MultichainAPI.Operations.getWalletActivities.Input.Query(
            limit: limit,
            cursor: cursor,
            chain: chain.map { $0.toAPISchemaChain() },
            activity_type: activityType.flatMap { MultichainAPI.Components.Schemas.ActivityType(rawValue: $0.rawValue) }
        )
        let output = try await apiCall(await multichainAPIClient.getWalletActivities(path: path, query: query))
        return try mapWalletActivitiesOutput(output)
    }

    func registerWallet(walletId: String, addresses: [MultichainWalletAddress]) async throws(MultichainClientAPIError) -> MultichainRegisteredWallet {
        let accounts = addresses.map {
            MultichainAPI.Components.Schemas.WalletAccount(
                chain: $0.chain.toAPISchemaChain(),
                address: $0.address
            )
        }
        let body = MultichainAPI.Components.RequestBodies.RegisterWallet.json(
            .init(
                wallet_id: walletId,
                accounts: accounts
            )
        )
        let output = try await apiCall(await multichainAPIClient.registerWallet(body: body))
        switch output {
        case let .ok(response):
            let wallet = try decodeResponse(response.body.json)
            return MultichainRegisteredWallet(api: wallet)
        case let .badRequest(error):
            throw try badRequest(from: error)
        case let .internalServerError(error):
            throw try internalError(from: error)
        case let .undocumented(statusCode, _):
            throw MultichainClientAPIError.undocumented(statusCode: statusCode)
        }
    }

    func broadcastTx(chain: MultichainChain, signedTransaction: Data) async throws(MultichainClientAPIError) -> MultichainBroadcastResult {
        let body = MultichainAPI.Components.RequestBodies.BroadcastTx.json(
            .init(
                chain: chain.toAPISchemaChain(),
                tx: Base64EncodedData(data: ArraySlice(signedTransaction))
            )
        )
        let output = try await apiCall(await multichainAPIClient.broadcastTx(body: body))
        switch output {
        case let .ok(result):
            let payload = try decodeResponse(result.body.json)
            return MultichainBroadcastResult(api: payload)
        case let .badRequest(error):
            throw try badRequest(from: error)
        case let .internalServerError(error):
            throw try internalError(from: error)
        case let .undocumented(statusCode, _):
            throw MultichainClientAPIError.undocumented(statusCode: statusCode)
        }
    }

    func getFees(chain: MultichainChain) async throws(MultichainClientAPIError) -> MultichainFeeEstimate {
        let path = MultichainAPI.Operations.getFees.Input.Path(chain: chain.toAPIParametersChainPath())
        let output = try await apiCall(await multichainAPIClient.getFees(path: path))
        switch output {
        case let .ok(fees):
            let estimate = try decodeResponse(fees.body.json)
            return MultichainFeeEstimate(api: estimate)
        case let .badRequest(error):
            throw try badRequest(from: error)
        case let .internalServerError(error):
            throw try internalError(from: error)
        case let .undocumented(statusCode, _):
            throw MultichainClientAPIError.undocumented(statusCode: statusCode)
        }
    }

    private func mapSearchAssetsOutput(_ output: MultichainAPI.Operations.searchAssets.Output) throws(MultichainClientAPIError) -> ([MultichainAsset], String?) {
        switch output {
        case let .ok(assets):
            let payload = try decodeResponse(assets.body.json)
            let list = payload.assets.map { MultichainAsset(api: $0, balance: .zero) }
            return (list, normalizedNextCursor(payload.next_cursor))
        case let .badRequest(error):
            throw try badRequest(from: error)
        case let .internalServerError(error):
            throw try internalError(from: error)
        case let .undocumented(statusCode, _):
            throw MultichainClientAPIError.undocumented(statusCode: statusCode)
        }
    }

    private func mapWalletAssetsOutput(_ output: MultichainAPI.Operations.getWalletAssets.Output) throws(MultichainClientAPIError) -> MultichainWalletAssetsPage {
        switch output {
        case let .ok(walletAssets):
            let payload = try decodeResponse(walletAssets.body.json)
            let assets = payload.assets.map { MultichainAsset(api: $0) }
            let fiat = payload.fiatPrice.additionalProperties
            return MultichainWalletAssetsPage(
                assets: assets,
                nextCursor: normalizedNextCursor(payload.next_cursor),
                fiatPrice: fiat
            )
        case let .badRequest(error):
            throw try badRequest(from: error)
        case let .notFound(error):
            throw try notFound(from: error)
        case let .internalServerError(error):
            throw try internalError(from: error)
        case let .undocumented(statusCode, _):
            throw MultichainClientAPIError.undocumented(statusCode: statusCode)
        }
    }

    private func mapWalletActivitiesOutput(_ output: MultichainAPI.Operations.getWalletActivities.Output) throws(MultichainClientAPIError) -> MultichainWalletActivitiesPage {
        switch output {
        case let .ok(activities):
            let payload = try decodeResponse(activities.body.json)
            let list = payload.activities.map { MultichainActivity(api: $0) }
            return MultichainWalletActivitiesPage(
                activities: list,
                nextCursor: payload.cursor.flatMap { normalizedNextCursor($0) }
            )
        case let .badRequest(error):
            throw try badRequest(from: error)
        case let .notFound(error):
            throw try notFound(from: error)
        case let .internalServerError(error):
            throw try internalError(from: error)
        case let .undocumented(statusCode, _):
            throw MultichainClientAPIError.undocumented(statusCode: statusCode)
        }
    }

    private func normalizedNextCursor(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func apiCall<T>(
        _ block: @autoclosure () async throws -> T
    ) async throws(MultichainClientAPIError) -> T {
        do {
            return try await block()
        } catch is CancellationError {
            throw .cancelled
        } catch {
            throw .connectionError
        }
    }

    private func decodeResponse<T>(
        _ block: @autoclosure () throws -> T
    ) throws(MultichainClientAPIError) -> T {
        do {
            return try block()
        } catch {
            throw .badResponse(underlying: error)
        }
    }

    private func badRequest(from response: MultichainAPI.Components.Responses.BadRequest) throws(MultichainClientAPIError) -> MultichainClientAPIError {
        try .badStatus(message: decodeResponse(response.body.json.error))
    }

    private func notFound(from response: MultichainAPI.Components.Responses.NotFound) throws(MultichainClientAPIError) -> MultichainClientAPIError {
        try .badStatus(message: decodeResponse(response.body.json.error))
    }

    private func internalError(from response: MultichainAPI.Components.Responses.InternalError) throws(MultichainClientAPIError) -> MultichainClientAPIError {
        try .badStatus(message: decodeResponse(response.body.json.error))
    }
}
