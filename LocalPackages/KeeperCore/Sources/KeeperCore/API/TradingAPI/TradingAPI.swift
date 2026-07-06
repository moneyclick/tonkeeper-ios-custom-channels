import Foundation
import TKTradingAPI

protocol TradingAPI {
    func getShelves(
        requestContext: TradingRequestContext
    ) async throws(TradingAPIError) -> Components.Schemas.ShelvesConfigResponse

    func getAssetsCatalog(
        requestContext: TradingRequestContext,
        tab: Components.Schemas.AssetsTab,
        query: String?,
        cursor: String?,
        pageSize: Int?,
        sourceShelf: String?
    ) async throws(TradingAPIError) -> Components.Schemas.AssetsCatalogResponse

    func getAssetsDetails(
        requestContext: TradingRequestContext,
        assetId: String
    ) async throws(TradingAPIError) -> Components.Schemas.AssetDetailsResponse
}

struct TradingAPIImplementation {
    private let hostProvider: APIHostProvider
    private let urlSession: URLSession

    init(
        hostProvider: APIHostProvider,
        urlSession: URLSession
    ) {
        self.hostProvider = hostProvider
        self.urlSession = urlSession
    }
}

// MARK: - Convenience

private extension TradingAPIImplementation {
    func apiClient() async throws(TradingAPIError) -> Client {
        do {
            return try await Client(
                hostProvider: hostProvider,
                urlSession: urlSession
            )
        } catch {
            switch error {
            case .badHost:
                throw .badUrl(underlying: error)
            }
        }
    }

    func apiCall<T>(
        _ block: @autoclosure () async throws -> T
    ) async throws(TradingAPIError) -> T {
        do {
            return try await block()
        } catch {
            throw .transportError(underlying: error)
        }
    }

    func decodeResponse<T>(
        _ block: @autoclosure () throws -> T
    ) throws(TradingAPIError) -> T {
        do {
            return try block()
        } catch {
            throw .badResponse(underlying: error)
        }
    }
}

// MARK: - API

extension TradingAPIImplementation: TradingAPI {
    func getShelves(
        requestContext: TradingRequestContext
    ) async throws(TradingAPIError) -> Components.Schemas.ShelvesConfigResponse {
        let client = try await apiClient()
        let response = try await apiCall(
            await client.getShelvesConfig(
                query: .init(
                    currency: requestContext.currency.code.lowercased(),
                    store_country_code: requestContext.storeCountryCode,
                    sim_country: requestContext.simCountryCode,
                    device_country_code: requestContext.deviceCountryCode,
                    timezone: requestContext.timezoneIdentifier,
                    is_vpn_active: requestContext.isVPNActive
                ),
                headers: .init(
                    User_hyphen_Agent: requestContext.userAgent,
                    X_hyphen_Lang: requestContext.language
                )
            )
        )

        switch response {
        case let .ok(ok):
            return try decodeResponse(ok.body.json)
        case let .badRequest(badRequest):
            throw try .badStatus(
                message: decodeResponse(badRequest.body.json).message
            )
        case let .unauthorized(unauthorized):
            throw try .badStatus(
                message: decodeResponse(unauthorized.body.json).message
            )
        case let .tooManyRequests(tooManyRequests):
            throw try .badStatus(
                message: decodeResponse(tooManyRequests.body.json).message
            )
        case let .internalServerError(internalServerError):
            throw try .badStatus(
                message: decodeResponse(internalServerError.body.json).message
            )
        case let .undocumented(statusCode, _):
            throw .badStatus(
                message: "undocumented status code: \(statusCode)"
            )
        }
    }

    func getAssetsCatalog(
        requestContext: TradingRequestContext,
        tab: Components.Schemas.AssetsTab,
        query: String?,
        cursor: String?,
        pageSize: Int?,
        sourceShelf: String?
    ) async throws(TradingAPIError) -> Components.Schemas.AssetsCatalogResponse {
        let client = try await apiClient()
        let response = try await apiCall(
            await client.getAssetsCatalog(
                query: .init(
                    currency: requestContext.currency.code.lowercased(),
                    store_country_code: requestContext.storeCountryCode,
                    sim_country: requestContext.simCountryCode,
                    device_country_code: requestContext.deviceCountryCode,
                    timezone: requestContext.timezoneIdentifier,
                    is_vpn_active: requestContext.isVPNActive,
                    tab: tab,
                    q: query,
                    source_shelf: sourceShelf,
                    cursor: cursor,
                    page_size: pageSize
                ),
                headers: .init(
                    User_hyphen_Agent: requestContext.userAgent,
                    X_hyphen_Lang: requestContext.language
                )
            )
        )
        switch response {
        case let .ok(ok):
            return try decodeResponse(ok.body.json)
        case let .badRequest(badRequest):
            throw try .badStatus(
                message: decodeResponse(badRequest.body.json).message
            )
        case let .unauthorized(unauthorized):
            throw try .badStatus(
                message: decodeResponse(unauthorized.body.json).message
            )
        case let .tooManyRequests(tooManyRequests):
            throw try .badStatus(
                message: decodeResponse(tooManyRequests.body.json).message
            )
        case let .internalServerError(internalServerError):
            throw try .badStatus(
                message: decodeResponse(internalServerError.body.json).message
            )
        case let .undocumented(statusCode, _):
            throw .badStatus(
                message: "undocumented status code: \(statusCode)"
            )
        }
    }

    func getAssetsDetails(
        requestContext: TradingRequestContext,
        assetId: String
    ) async throws(TradingAPIError) -> Components.Schemas.AssetDetailsResponse {
        let client = try await apiClient()
        let response = try await apiCall(
            await client.getAssetDetails(
                path: .init(assetId: assetId),
                query: .init(
                    currency: requestContext.currency.code.lowercased(),
                    store_country_code: requestContext.storeCountryCode,
                    sim_country: requestContext.simCountryCode,
                    device_country_code: requestContext.deviceCountryCode,
                    timezone: requestContext.timezoneIdentifier,
                    is_vpn_active: requestContext.isVPNActive
                ),
                headers: .init(
                    User_hyphen_Agent: requestContext.userAgent,
                    X_hyphen_Lang: requestContext.language
                )
            )
        )
        switch response {
        case let .ok(ok):
            return try decodeResponse(ok.body.json)
        case let .badRequest(badRequest):
            throw try .badStatus(
                message: decodeResponse(badRequest.body.json).message
            )
        case let .unauthorized(unauthorized):
            throw try .badStatus(
                message: decodeResponse(unauthorized.body.json).message
            )
        case let .tooManyRequests(tooManyRequests):
            throw try .badStatus(
                message: decodeResponse(tooManyRequests.body.json).message
            )
        case let .internalServerError(internalServerError):
            throw try .badStatus(
                message: decodeResponse(internalServerError.body.json).message
            )
        case .notFound:
            throw .badStatus(
                message: "Asset not found"
            )
        case let .undocumented(statusCode, _):
            throw .badStatus(
                message: "undocumented status code: \(statusCode)"
            )
        }
    }
}
