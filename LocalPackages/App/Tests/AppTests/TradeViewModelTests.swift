@testable import App
@testable import KeeperCore
import TKCore
import XCTest

final class TradeViewModelTests: XCTestCase {
    @MainActor
    func test_loadIfNeeded_derivesAssetCategoryFromAssetID() async {
        let service = TradingShelvesServiceSpy(
            snapshot: TradingShelvesSnapshot(
                generatedAt: .now,
                currency: .USD,
                shelves: [
                    TradingShelf(
                        id: "shelf",
                        title: "Shelf",
                        grids: [
                            TradingShelfGrid(
                                id: "most_traded",
                                name: "Most traded",
                                source: "api",
                                seeAllCategory: .all,
                                items: [
                                    TradingMarketItem(
                                        id: "ton/mainnet/stocks/0:abcdef",
                                        symbol: "TSLAx",
                                        name: "Tesla",
                                        category: .stocks,
                                        imageURL: nil,
                                        price: nil,
                                        change24hPercent: nil,
                                        isUnverified: false
                                    ),
                                ]
                            ),
                        ]
                    ),
                ]
            )
        )
        let viewModel = makeViewModel(shelvesService: service)

        viewModel.loadIfNeeded()

        await waitUntil {
            await MainActor.run {
                viewModel.shelves.first?.grids.first?.items.first?.category == .stocks
            }
        }
    }

    @MainActor
    func test_scrollToGrid_selectsGridAndRequestsParentShelfScrollAfterShelvesLoad() async {
        let service = TradingShelvesServiceSpy(snapshot: makeGridSelectionSnapshot())
        let viewModel = makeViewModel(shelvesService: service)

        viewModel.scrollToGrid(id: "target_grid")
        XCTAssertNil(viewModel.scrollToShelfRequest)

        viewModel.loadIfNeeded()

        await waitUntil {
            await MainActor.run {
                viewModel.selectedGridIDs["shelf-2"] == "target_grid"
                    && viewModel.scrollToShelfRequest?.shelfID == "shelf-2"
            }
        }
    }

    @MainActor
    func test_scrollToGrid_repeatsScrollRequestWhenGridAlreadySelected() async {
        let service = TradingShelvesServiceSpy(snapshot: makeGridSelectionSnapshot())
        let viewModel = makeViewModel(shelvesService: service)

        viewModel.loadIfNeeded()

        await waitUntil {
            await MainActor.run {
                viewModel.shelves.count == 2
            }
        }

        viewModel.scrollToGrid(id: "target_grid")
        let firstRequest = viewModel.scrollToShelfRequest
        XCTAssertEqual(firstRequest?.shelfID, "shelf-2")
        XCTAssertEqual(viewModel.selectedGridIDs["shelf-2"], "target_grid")

        viewModel.scrollToGrid(id: "target_grid")

        XCTAssertEqual(viewModel.scrollToShelfRequest?.shelfID, "shelf-2")
        XCTAssertEqual(viewModel.scrollToShelfRequest?.id, (firstRequest?.id ?? 0) + 1)
    }
}

private extension TradeViewModelTests {
    @MainActor
    func makeViewModel(shelvesService: TradingShelvesService) -> TradeViewModel {
        let formattersAssembly = FormattersAssembly()
        return TradeViewModel(
            analyticsProvider: AnalyticsProvider(
                analyticsServices: [],
                uniqueIdProvider: CoreAssembly().uniqueIdProvider,
                appInfoProvider: CoreAssembly().appInfoProvider
            ),
            analyticsSource: .deepLink,
            shelvesService: shelvesService,
            amountFormatter: formattersAssembly.amountFormatter,
            signedAmountFormatter: formattersAssembly.signedAmountFormatter,
            onOpenAssetList: { _ in },
            onOpenAssetDetails: { _ in }
        )
    }

    func makeGridSelectionSnapshot() -> TradingShelvesSnapshot {
        TradingShelvesSnapshot(
            generatedAt: .now,
            currency: .USD,
            shelves: [
                TradingShelf(
                    id: "shelf-1",
                    title: "Shelf 1",
                    grids: [
                        makeGrid(id: "popular_grid"),
                    ]
                ),
                TradingShelf(
                    id: "shelf-2",
                    title: "Shelf 2",
                    grids: [
                        makeGrid(id: "default_grid"),
                        makeGrid(id: "target_grid"),
                    ]
                ),
            ]
        )
    }

    func makeGrid(id: String) -> TradingShelfGrid {
        TradingShelfGrid(
            id: id,
            name: id,
            source: "api",
            seeAllCategory: .all,
            items: [
                TradingMarketItem(
                    id: "ton/mainnet/coin",
                    symbol: "TON",
                    name: "Toncoin",
                    category: .crypto,
                    imageURL: nil,
                    price: nil,
                    change24hPercent: nil,
                    isUnverified: false
                ),
            ]
        )
    }

    func waitUntil(
        timeout: TimeInterval = 2,
        intervalNanoseconds: UInt64 = 10_000_000,
        condition: @escaping () async -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if await condition() {
                return
            }

            try? await Task.sleep(nanoseconds: intervalNanoseconds)
        }

        XCTFail("Timed out waiting for condition")
    }
}

private actor TradingShelvesServiceSpy: TradingShelvesService {
    let snapshot: TradingShelvesSnapshot

    var shelves: TradingShelvesSnapshot? {
        get async { snapshot }
    }

    init(snapshot: TradingShelvesSnapshot) {
        self.snapshot = snapshot
    }

    func loadShelves() async throws(LoadShelvesFailure) -> TradingShelvesSnapshot {
        snapshot
    }
}
