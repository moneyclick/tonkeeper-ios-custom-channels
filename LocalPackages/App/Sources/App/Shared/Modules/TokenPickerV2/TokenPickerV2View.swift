import SwiftUI
import TKLocalize
import TKUIKit
import UIKit

enum TokenPickerV2RowContent {
    case skeleton
    case content(AssetBalanceRowCellContent)
}

struct TokenPickerV2RowView: View {
    let content: TokenPickerV2RowContent
    let showsDivider: Bool
    let action: (() -> Void)?

    var body: some View {
        AssetBalanceRowCell(
            config: cellConfig,
            showsDivider: showsDivider,
            action: action
        )
        .allowsHitTesting(isHitTestingEnabled)
    }
}

private extension TokenPickerV2RowView {
    var cellConfig: AssetBalanceRowCellConfig {
        switch content {
        case .skeleton:
            return .shimmer
        case let .content(content):
            return .content(content)
        }
    }

    var isHitTestingEnabled: Bool {
        switch content {
        case .skeleton:
            return false
        case .content:
            return true
        }
    }
}

struct TokenPickerV2HeaderView: View {
    @ObservedObject var viewModel: TokenPickerV2ViewModelImplementation
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            titleRow
                .padding(.horizontal, Layout.closeButtonPadding)
                .padding(.top, Layout.topPadding)
                .padding(.bottom, Layout.titleBottomPadding)

            SearchField(
                title: TKLocales.TokensPicker.Search.placeholder,
                text: Binding(
                    get: { viewModel.searchText },
                    set: viewModel.search(text:)
                ),
                isFocused: $isSearchFocused
            )
            .padding(.bottom, Layout.searchBottomPadding)

            if !viewModel.tabs.isEmpty {
                TabCategoriesView(
                    items: viewModel.tabs.map { tab in
                        TabCategoriesView<TokenPickerV2ChainFilter>.Item(
                            id: tab.id,
                            title: tab.title,
                            image: tab.image,
                            isSelectable: tab.isSelectable
                        )
                    },
                    initialSelection: viewModel.selectedChainFilter,
                    onSelectionChange: { selection in
                        viewModel.selectChainFilter(selection)
                    }
                )
                .padding(.bottom, Layout.tabsBottomPadding)
            }
        }
        .padding(.horizontal, Layout.contentHorizontalPadding)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color(uiColor: .Background.page))
    }

    private var titleRow: some View {
        ZStack(alignment: .center) {
            Text(TKLocales.Trade.Assets.Categories.crypto)
                .textStyle(.h3)
                .foregroundStyle(Color(uiColor: .Text.primary))

            HStack {
                Spacer()
                Button(action: viewModel.close) {
                    SwiftUI.Image(uiImage: .TKUIKit.Icons.Size16.close)
                        .renderingMode(.template)
                        .foregroundStyle(Color(uiColor: .Button.secondaryForeground))
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(uiColor: .Button.secondaryBackground))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: Layout.titleHeight)
        .frame(maxWidth: .infinity)
    }
}

private extension TokenPickerV2HeaderView {
    enum Layout {
        static let closeButtonPadding: CGFloat = 8
        static let contentHorizontalPadding: CGFloat = 16
        static let searchBottomPadding: CGFloat = 8
        static let tabsBottomPadding: CGFloat = 8
        static let titleBottomPadding: CGFloat = 8
        static let titleHeight: CGFloat = 48
        static let topPadding: CGFloat = 8
    }
}
