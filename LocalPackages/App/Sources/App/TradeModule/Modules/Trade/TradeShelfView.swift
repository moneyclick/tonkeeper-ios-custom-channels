import SwiftUI
import TKLocalize
import TKUIKit

enum TradeShelfViewContent {
    case skeleton(
        hasHeader: Bool,
        itemsCount: Int
    )
    case content(
        shelf: TradeViewModel.ShelfViewData,
        onOpenSeeAll: (TradeViewModel.ShelfViewData.GridViewData) -> Void,
        onOpenAsset: (TradeViewModel.AssetViewData) -> Void
    )
}

struct TradeShelfView: View {
    let content: TradeShelfViewContent
    let selectedGridID: String?
    let onSelectGrid: (String) -> Void

    private struct SkeletonAssetItem: Identifiable {
        let id: Int
    }

    init(
        content: TradeShelfViewContent,
        selectedGridID: String? = nil,
        onSelectGrid: @escaping (String) -> Void = { _ in }
    ) {
        self.content = content
        self.selectedGridID = selectedGridID
        self.onSelectGrid = onSelectGrid
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ListTitleView(
                config: listTitleConfig
            )
            grid
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    private var listTitleConfig: ListTitleView.Config {
        switch content {
        case .skeleton:
            .shimmer
        case let .content(shelf, onOpenSeeAll, _):
            .text(
                shelf.title,
                accessory: {
                    if let selectedGrid = selectedGrid(for: shelf), selectedGrid.seeAllEnabled {
                        ListTitleView.Accessory(
                            title: TKLocales.Trade.AssetDetails.Common.seeAll,
                            action: {
                                onOpenSeeAll(selectedGrid)
                            }
                        )
                    } else {
                        nil
                    }
                }()
            )
        }
    }

    @ViewBuilder private var grid: some View {
        switch content {
        case let .skeleton(_, itemsCount):
            AssetsGridView(
                items: .constant((0 ..< itemsCount).map(SkeletonAssetItem.init)),
                itemByModel: { _ in
                    AssetItemView(content: .shimmer, action: {})
                },
                header: {
                    gridHeader
                }
            )
        case let .content(shelf, _, onOpenAsset):
            let selectedGrid = selectedGrid(for: shelf)
            if let selectedGrid {
                AssetsGridView(
                    items: .constant(selectedGrid.items),
                    itemByModel: { item in
                        AssetItemView(
                            symbol: item.symbol,
                            imageSource: item.iconImageSource,
                            changeText: item.changeText,
                            changeColor: Color(uiColor: item.changeColor),
                            action: {
                                onOpenAsset(item)
                            }
                        )
                        .id(item.id)
                    },
                    header: {
                        gridHeader
                    }
                )
            }
        }
    }

    @ViewBuilder private var gridHeader: some View {
        switch content {
        case let .skeleton(hasHeader, _):
            if hasHeader {
                paddedHeader(
                    content: SegmentedControlShimmer()
                )
            }
        case let .content(shelf, _, _):
            if shelf.grids.count > 1 {
                paddedHeader(
                    content: SegmentedControl(
                        segments: shelf.grids.map {
                            .init(id: $0.id, title: $0.name)
                        },
                        initialSelection: selectedGrid(for: shelf)?.id ?? shelf.grids[0].id
                    ) { selectedGridID in
                        onSelectGrid(selectedGridID)
                    }
                )
            }
        }
    }

    private func paddedHeader(content: some View) -> some View {
        content
            .padding(.horizontal, Layout.headerHorizontalPadding)
            .padding(.bottom, Layout.headerBottomPadding)
    }
}

private extension TradeShelfView {
    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let headerBottomPadding: CGFloat = 8
        static let headerHorizontalPadding: CGFloat = 8
    }

    func selectedGrid(for shelf: TradeViewModel.ShelfViewData) -> TradeViewModel.ShelfViewData.GridViewData? {
        guard let selectedGridID else {
            return shelf.grids.first
        }
        return shelf.grids.first(where: { $0.id == selectedGridID }) ?? shelf.grids.first
    }
}
