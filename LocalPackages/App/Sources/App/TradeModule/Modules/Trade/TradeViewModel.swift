import Foundation
import KeeperCore
import TKCore
import TKLocalize
import TKUIKit
import UIKit

@MainActor
final class TradeViewModel: ObservableObject {
    struct ShelfViewData: Identifiable {
        struct GridViewData: Identifiable {
            var id: String
            var name: String
            var items: [AssetViewData]
            var seeAllCategory: TradingAssetCategory?

            var seeAllEnabled: Bool {
                seeAllCategory != nil
            }
        }

        let id: String
        let title: String
        let grids: [GridViewData]
    }

    struct AssetViewData: Identifiable {
        let asset: TradingMarketItem
        let id: String
        let category: TradingAssetCategory
        let symbol: String
        let name: String
        let chainTag: String?
        let iconImageSource: AssetAvatarViewImageSource
        let priceText: String
        let changeValue: Decimal?
        let changeText: String?
        let changeColor: UIColor
    }

    struct ScrollToShelfRequest: Equatable {
        let id: Int
        let shelfID: String
    }

    @Published private(set) var shelves = [ShelfViewData]()
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var scrollToTopRequestID = 0
    @Published private(set) var scrollToShelfRequest: ScrollToShelfRequest?
    @Published private(set) var selectedGridIDs = [String: String]()

    private let analyticsProvider: AnalyticsProvider
    private let analyticsSource: TradeFlowAnalyticsSource
    private let shelvesService: TradingShelvesService
    private let amountFormatter: AmountFormatter
    private let signedAmountFormatter: AmountFormatter
    private let onOpenAssetList: (TradingAssetCategory) -> Void
    private let onOpenAssetDetails: (TradingMarketItem) -> Void

    private var hasLoaded = false
    private var pendingGridID: String?
    private var scrollToShelfRequestID = 0

    init(
        analyticsProvider: AnalyticsProvider,
        analyticsSource: TradeFlowAnalyticsSource,
        shelvesService: TradingShelvesService,
        amountFormatter: AmountFormatter,
        signedAmountFormatter: AmountFormatter,
        onOpenAssetList: @escaping (TradingAssetCategory) -> Void,
        onOpenAssetDetails: @escaping (TradingMarketItem) -> Void
    ) {
        self.analyticsProvider = analyticsProvider
        self.analyticsSource = analyticsSource
        self.shelvesService = shelvesService
        self.amountFormatter = amountFormatter
        self.signedAmountFormatter = signedAmountFormatter
        self.onOpenAssetList = onOpenAssetList
        self.onOpenAssetDetails = onOpenAssetDetails
    }

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true

        Task {
            if let cachedShelves = await shelvesService.shelves {
                apply(cachedShelves)
            }
            await refresh()
        }
    }

    func refresh() async {
        isLoading = true
        defer {
            isLoading = false
        }

        do {
            let snapshot = try await shelvesService.loadShelves()
            errorMessage = nil
            apply(snapshot)
        } catch {
            if shelves.isEmpty {
                errorMessage = TKLocales.Trade.Errors.loadShelves
            }
        }
    }

    func openSearch() {
        onOpenAssetList(.all)
    }

    func openAsset(_ asset: AssetViewData) {
        analyticsProvider.log(
            TradeClickAsset(from: analyticsSource.tradeClickAsset, asset: asset.id)
        )
        onOpenAssetDetails(asset.asset)
    }

    func openSeeAll(for grid: ShelfViewData.GridViewData) {
        guard let category = grid.seeAllCategory else {
            return
        }
        onOpenAssetList(category)
    }

    func scrollToTop() {
        scrollToTopRequestID += 1
    }

    func scrollToGrid(id gridID: String) {
        guard selectGridAndRequestScroll(gridID: gridID) else {
            pendingGridID = gridID
            return
        }
    }

    func selectedGridID(for shelf: ShelfViewData) -> String? {
        selectedGridIDs[shelf.id]
    }

    func selectGrid(id gridID: String, for shelf: ShelfViewData) {
        guard shelf.grids.contains(where: { $0.id == gridID }) else {
            return
        }
        selectedGridIDs[shelf.id] = gridID
    }
}

private extension TradeViewModel {
    func apply(_ snapshot: TradingShelvesSnapshot) {
        shelves = snapshot.shelves.map { shelf in
            ShelfViewData(
                id: shelf.id,
                title: shelf.title,
                grids: shelf.grids.map { grid in
                    ShelfViewData.GridViewData(
                        id: grid.id,
                        name: grid.name,
                        items: grid.items.map {
                            mapAsset(
                                $0,
                                currency: snapshot.currency
                            )
                        },
                        seeAllCategory: grid.seeAllCategory
                    )
                }
            )
        }
        pruneSelectedGridIDs()
        if let pendingGridID {
            _ = selectGridAndRequestScroll(gridID: pendingGridID)
        }
    }

    func mapAsset(
        _ item: TradingMarketItem,
        currency: Currency
    ) -> AssetViewData {
        AssetViewData(
            asset: item,
            id: item.id,
            category: item.category,
            symbol: item.symbol,
            name: item.name,
            chainTag: AssetIdResolver.tag(for: item.id),
            iconImageSource: AssetIdResolver.imageSource(for: item.id, imageUrl: item.imageURL),
            priceText: formatPrice(item.price, currency: currency),
            changeValue: item.change24hPercent,
            changeText: formatChange(item.change24hPercent),
            changeColor: (item.change24hPercent ?? 0) < 0 ? .Accent.red : .Accent.green
        )
    }

    func formatPrice(_ price: Decimal?, currency: Currency) -> String {
        guard let price else {
            return "..."
        }

        return amountFormatter.format(
            decimal: price,
            accessory: .fiat(currency),
            style: .compact
        )
    }

    func formatChange(_ change24hPercent: Decimal?) -> String? {
        guard let change24hPercent else {
            return nil
        }

        return signedAmountFormatter.format(
            decimal: change24hPercent,
            style: .percent
        )
    }

    @discardableResult
    func selectGridAndRequestScroll(gridID: String) -> Bool {
        guard let shelf = shelves.first(where: { shelf in
            shelf.grids.contains(where: { $0.id == gridID })
        }) else {
            return false
        }

        selectedGridIDs[shelf.id] = gridID
        scrollToShelfRequestID += 1
        scrollToShelfRequest = ScrollToShelfRequest(
            id: scrollToShelfRequestID,
            shelfID: shelf.id
        )

        if pendingGridID == gridID {
            pendingGridID = nil
        }

        return true
    }

    func pruneSelectedGridIDs() {
        selectedGridIDs = selectedGridIDs.filter { shelfID, gridID in
            shelves.contains { shelf in
                shelf.id == shelfID && shelf.grids.contains(where: { $0.id == gridID })
            }
        }
    }
}
