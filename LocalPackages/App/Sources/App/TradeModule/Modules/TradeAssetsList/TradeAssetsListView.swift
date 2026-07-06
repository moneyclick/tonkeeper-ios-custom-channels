import KeeperCore
import SwiftUI
import TKLocalize
import TKUIKit

struct TradeAssetsListView: View {
    private enum Constants {
        static let autoFocusDelayNanoseconds: UInt64 = 150_000_000
    }

    @ObservedObject var viewModel: TradeAssetsListViewModel
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            Color(uiColor: .Background.page)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                searchField
                categoriesPicker

                ZStack {
                    ForEach(viewModel.categories) { category in
                        TradeAssetsListContentView(
                            viewModel: viewModel.contentViewModel(for: category),
                            onOpenAsset: viewModel.openAsset,
                            onScrollStarted: {
                                isSearchFocused = false
                            }
                        )
                        .opacity(category != viewModel.selectedCategory ? 0 : 1)
                        .allowsHitTesting(category == viewModel.selectedCategory)
                        .id(category)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .task {
            viewModel.loadIfNeeded()
            try? await Task.sleep(nanoseconds: Constants.autoFocusDelayNanoseconds)
            isSearchFocused = true
        }
    }

    private var header: some View {
        DefaultModalCardHeader(
            config: DefaultModalCardHeader.Config(
                title: DefaultModalCardHeader.Title(
                    text: TKLocales.Trade.Assets.title
                ),
                rightIcon: .close(
                    onTap: { _ in
                        viewModel.close()
                    }
                )
            )
        )
    }

    private var searchField: some View {
        SearchField(
            insetsModifier: { insets in
                insets.top = 0
                insets.bottom = Layout.searchFieldBottomPadding
            },
            title: TKLocales.Trade.Search.placeholder,
            text: Binding(
                get: {
                    viewModel.searchText
                },
                set: viewModel.updateSearchText
            ),
            isFocused: $isSearchFocused
        )
    }

    private var categoriesPicker: some View {
        TabCategoriesView(
            items: viewModel.categories
                .map { category in
                    TabCategoriesView.Item(
                        id: category.id,
                        title: title(for: category)
                    )
                },
            initialSelection: viewModel.selectedCategory.id,
            onSelectionChange: { id in
                viewModel.categories
                    .first { $0.id == id }
                    .map(viewModel.selectCategory)
            }
        )
    }

    private func title(for category: TradingAssetCategory) -> String {
        switch category {
        case .all:
            TKLocales.Trade.Assets.Categories.all
        case .crypto:
            TKLocales.Trade.Assets.Categories.crypto
        case .stocks:
            TKLocales.Trade.Assets.Categories.stocks
        case .etfs:
            TKLocales.Trade.Assets.Categories.etfs
        }
    }

    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let searchFieldBottomPadding: CGFloat = 8
    }
}
