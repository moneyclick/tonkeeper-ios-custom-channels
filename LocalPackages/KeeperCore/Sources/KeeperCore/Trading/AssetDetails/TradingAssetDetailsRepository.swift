protocol TradingAssetDetailsRepository {
    func assetDetails(
        for assetId: String
    ) async -> TradingAssetDetails?

    func setAssetDetails(
        _ value: TradingAssetDetails,
        for assetId: String
    ) async
}

actor TradingAssetDetailsRepositoryImplementation {
    private var cache: [String: TradingAssetDetails] = [:]
}

extension TradingAssetDetailsRepositoryImplementation: TradingAssetDetailsRepository {
    func assetDetails(
        for assetId: String
    ) -> TradingAssetDetails? {
        cache[assetId]
    }

    func setAssetDetails(
        _ value: TradingAssetDetails,
        for assetId: String
    ) {
        cache[assetId] = value
    }
}
