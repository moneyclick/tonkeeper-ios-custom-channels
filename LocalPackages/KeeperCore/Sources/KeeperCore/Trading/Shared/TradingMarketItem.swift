import Foundation
import TKTradingAPI

public struct TradingMarketItem: Equatable, Identifiable, Sendable {
    public var id: String
    public var symbol: String
    public var name: String
    public var category: TradingAssetCategory
    public var imageURL: URL?
    public var price: Decimal?
    public var change24hPercent: Decimal?
    public var isUnverified: Bool
}

extension TradingMarketItem {
    init(item: Components.Schemas.MarketItem) {
        self.init(
            id: item.asset.id,
            symbol: item.asset.symbol,
            name: item.asset.name,
            category: item.asset.asset_type.asCategory,
            imageURL: URL(string: item.asset.image_url),
            price: item.metrics.price.decimalValue,
            change24hPercent: item.metrics.change_24h_percent.decimalValue,
            isUnverified: item.asset.verification != .whitelist
        )
    }
}

private extension String {
    var decimalValue: Decimal? {
        Decimal(string: self, locale: Locale(identifier: "en_US_POSIX"))
    }
}

extension Components.Schemas.AssetType {
    var asCategory: TradingAssetCategory {
        switch self {
        case .asset:
            .crypto
        case .stocks:
            .stocks
        case .etfs:
            .etfs
        }
    }
}
