protocol TradingAssetsListRepository {
    func assetsListSnapshot(
        query: String?,
        category: TradingAssetCategory
    ) async -> TradingAssetListSnapshot?

    func setAssetsListSnapshot(
        _ value: TradingAssetListSnapshot,
        query: String?,
        category: TradingAssetCategory
    ) async
}

actor TradingAssetsListRepositoryImplementation {
    struct Key: Hashable {
        var query: String?
        var category: TradingAssetCategory
    }

    private var cache: [Key: TradingAssetListSnapshot] = [:]

    init() {}
}

extension TradingAssetsListRepositoryImplementation: TradingAssetsListRepository {
    func assetsListSnapshot(
        query: String?,
        category: TradingAssetCategory
    ) -> TradingAssetListSnapshot? {
        cache[Key(query: query, category: category)]
    }

    func setAssetsListSnapshot(
        _ value: TradingAssetListSnapshot,
        query: String?,
        category: TradingAssetCategory
    ) {
        cache[Key(query: query, category: category)] = value
    }
}
