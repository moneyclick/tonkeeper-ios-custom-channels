import TKLogging
import TKTradingAPI

actor TradingAssetDetailsServiceImplementation {
    private let api: TradingAPI
    private let repository: TradingAssetDetailsRepository
    private let requestContextProvider: TradingRequestContextProvider

    init(
        api: TradingAPI,
        repository: TradingAssetDetailsRepository,
        requestContextProvider: TradingRequestContextProvider
    ) {
        self.api = api
        self.repository = repository
        self.requestContextProvider = requestContextProvider
    }
}

extension TradingAssetDetailsServiceImplementation: TradingAssetDetailsService {
    func assetDetails(
        for assetId: String
    ) async -> TradingAssetDetails? {
        await repository.assetDetails(for: assetId)
    }

    func loadAssetDetails(
        id: String
    ) async throws(TradingAssetDetailsServiceFailure) -> TradingAssetDetails {
        Log.trade.i("load details for asset \(id)")
        let requestContext = await requestContextProvider.makeRequestContext()
        let response: Components.Schemas.AssetDetailsResponse
        do {
            response = try await api.getAssetsDetails(
                requestContext: requestContext,
                assetId: id
            )
        } catch {
            Log.trade.i("load details failed \(error.localizedDescription)")
            switch error {
            case .transportError:
                throw .networkError
            default:
                throw .apiError(message: error.localizedDescription)
            }
        }
        let details = TradingAssetDetails(
            response: response,
            currency: requestContext.currency
        )
        await repository.setAssetDetails(details, for: id)
        Log.trade.i("load details for asset \(id) - success")
        return details
    }
}
