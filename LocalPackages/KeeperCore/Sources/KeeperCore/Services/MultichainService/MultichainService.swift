import Foundation

public enum MultichainServiceError: Error {
    case cancelled
    case connectionError
    case apiError(
        message: String?
    )
}

public protocol MultichainService {
    func healthcheck() async throws(MultichainServiceError) -> MultichainHealth
    func getNodes(ifNoneMatch: String?) async throws(MultichainServiceError) -> MultichainNodesResponse
    func searchAssets(
        currencies: [String],
        chain: MultichainChain?,
        search: String?,
        sort: MultichainAssetSearchSort,
        limit: Int?,
        cursor: String?
    ) async throws(MultichainServiceError) -> (assets: [MultichainAsset], nextCursor: String?)
    func getWallet(walletId: String) async throws(MultichainServiceError) -> MultichainRegisteredWallet
    func getWalletAssets(
        walletId: String,
        currencies: [String],
        chain: MultichainChain?,
        search: String?,
        availableOnly: Bool?,
        showHidden: Bool?,
        limit: Int?,
        cursor: String?
    ) async throws(MultichainServiceError) -> MultichainWalletAssetsPage
    func saveWalletAssetsFilters(walletId: String, changes: [MultichainAssetFilterChange]) async throws(MultichainServiceError)
    func getWalletActivities(
        walletId: String,
        limit: Int?,
        cursor: String?,
        chain: MultichainChain?,
        activityType: MultichainActivityType?
    ) async throws(MultichainServiceError) -> MultichainWalletActivitiesPage
    func registerWallet(walletId: String, addresses: [MultichainWalletAddress]) async throws(MultichainServiceError) -> MultichainRegisteredWallet
    func broadcastTx(chain: MultichainChain, signedTransaction: Data) async throws(MultichainServiceError) -> MultichainBroadcastResult
    func getFees(chain: MultichainChain) async throws(MultichainServiceError) -> MultichainFeeEstimate
}

final class MultichainServiceImplementation: MultichainService {
    private let multichainClientAPI: MultichainClientAPI

    init(multichainClientAPI: MultichainClientAPI) {
        self.multichainClientAPI = multichainClientAPI
    }

    func healthcheck() async throws(MultichainServiceError) -> MultichainHealth {
        try await serviceCall(await multichainClientAPI.healthcheck())
    }

    func getNodes(ifNoneMatch: String?) async throws(MultichainServiceError) -> MultichainNodesResponse {
        try await serviceCall(await multichainClientAPI.getNodes(ifNoneMatch: ifNoneMatch))
    }

    func searchAssets(
        currencies: [String],
        chain: MultichainChain?,
        search: String?,
        sort: MultichainAssetSearchSort,
        limit: Int?,
        cursor: String?
    ) async throws(MultichainServiceError) -> (assets: [MultichainAsset], nextCursor: String?) {
        try await serviceCall(await multichainClientAPI.searchAssets(
            currencies: currencies,
            chain: chain,
            search: search,
            sort: sort,
            limit: limit,
            cursor: cursor
        ))
    }

    func getWallet(walletId: String) async throws(MultichainServiceError) -> MultichainRegisteredWallet {
        try await serviceCall(await multichainClientAPI.getWallet(walletId: walletId))
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
    ) async throws(MultichainServiceError) -> MultichainWalletAssetsPage {
        try await serviceCall(await multichainClientAPI.getWalletAssets(
            walletId: walletId,
            currencies: currencies,
            chain: chain,
            search: search,
            availableOnly: availableOnly,
            showHidden: showHidden,
            limit: limit,
            cursor: cursor
        ))
    }

    func saveWalletAssetsFilters(walletId: String, changes: [MultichainAssetFilterChange]) async throws(MultichainServiceError) {
        try await serviceCall(await multichainClientAPI.saveWalletAssetsFilters(walletId: walletId, changes: changes))
    }

    func getWalletActivities(
        walletId: String,
        limit: Int?,
        cursor: String?,
        chain: MultichainChain?,
        activityType: MultichainActivityType?
    ) async throws(MultichainServiceError) -> MultichainWalletActivitiesPage {
        try await serviceCall(await multichainClientAPI.getWalletActivities(
            walletId: walletId,
            limit: limit,
            cursor: cursor,
            chain: chain,
            activityType: activityType
        ))
    }

    func registerWallet(walletId: String, addresses: [MultichainWalletAddress]) async throws(MultichainServiceError) -> MultichainRegisteredWallet {
        try await serviceCall(await multichainClientAPI.registerWallet(walletId: walletId, addresses: addresses))
    }

    func broadcastTx(chain: MultichainChain, signedTransaction: Data) async throws(MultichainServiceError) -> MultichainBroadcastResult {
        try await serviceCall(await multichainClientAPI.broadcastTx(chain: chain, signedTransaction: signedTransaction))
    }

    func getFees(chain: MultichainChain) async throws(MultichainServiceError) -> MultichainFeeEstimate {
        try await serviceCall(await multichainClientAPI.getFees(chain: chain))
    }
}

private extension MultichainServiceImplementation {
    func serviceCall<T>(
        _ block: @autoclosure () async throws(MultichainClientAPIError) -> T
    ) async throws(MultichainServiceError) -> T {
        do {
            return try await block()
        } catch {
            throw Self.mapError(error)
        }
    }

    static func mapError(_ error: MultichainClientAPIError) -> MultichainServiceError {
        switch error {
        case .cancelled:
            return .cancelled
        case .connectionError:
            return .connectionError
        case .badResponse:
            return .apiError(message: nil)
        case let .badStatus(message):
            return .apiError(message: message)
        case let .undocumented(statusCode):
            return .apiError(message: "HTTP \(statusCode)")
        }
    }
}
