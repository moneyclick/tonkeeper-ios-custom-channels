import Foundation
import TKTradingAPI

public struct TradingShelfGrid: Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var source: String
    public var seeAllCategory: TradingAssetCategory?
    public var items: [TradingMarketItem]

    init?(config: Components.Schemas.ShelfConfig) {
        let items = (config.items ?? []).compactMap(TradingMarketItem.init(item:))
        guard !items.isEmpty else {
            return nil
        }
        self.init(
            id: config.key.rawValue,
            name: config.title,
            source: config.source,
            seeAllCategory: config.see_all.enabled
                ? TradingAssetCategory(tradingApiValue: config.see_all.route)
                : nil,
            items: items
        )
    }

    init(
        id: String,
        name: String,
        source: String,
        seeAllCategory: TradingAssetCategory?,
        items: [TradingMarketItem]
    ) {
        self.id = id
        self.name = name
        self.source = source
        self.seeAllCategory = seeAllCategory
        self.items = items
    }
}

public struct TradingShelf: Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var grids: [TradingShelfGrid]
}

extension TradingShelf {
    init?(shelf: Components.Schemas.ShelfGroup) {
        let grids = shelf.items.compactMap(TradingShelfGrid.init(config:))
        guard !grids.isEmpty else {
            return nil
        }
        self.init(
            id: Self.stableID(for: shelf),
            title: shelf.name,
            grids: grids
        )
    }

    private static func stableID(for shelf: Components.Schemas.ShelfGroup) -> String {
        let gridIDs = shelf.items.map(\.key.rawValue).joined(separator: "|")
        return "\(shelf.name)|\(gridIDs)"
    }
}
