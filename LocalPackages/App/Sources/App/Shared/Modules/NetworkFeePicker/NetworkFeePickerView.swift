import SwiftUI
import TKUIKit

struct NetworkFeePickerView: View {
    @ObservedObject var viewModel: NetworkFeePickerViewModelImplementation

    var body: some View {
        VStack(spacing: 0) {
            categoriesSection
            itemsSection
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color(uiColor: .Background.page))
    }
}

private extension NetworkFeePickerView {
    enum Layout {
        static let contentHorizontalInset: CGFloat = 16
        static let categoriesBottomInset: CGFloat = 16
        static let itemsBottomInset: CGFloat = 4
        static let skeletonItemCount = 3
    }

    @ViewBuilder
    var categoriesSection: some View {
        switch viewModel.viewState {
        case .list:
            EmptyView()
        case .loading:
            SegmentedControlShimmer()
                .padding(.horizontal, Layout.contentHorizontalInset)
                .padding(.bottom, Layout.categoriesBottomInset)
        case let .categories(categories, selectedCategoryID):
            SegmentedControl(
                segments: categories.map { category in
                    SegmentedControl<NetworkFeePickerCategory.ID>.Segment(
                        id: category.id,
                        title: category.title,
                        icon: category.icon.map {
                            .init(
                                image: $0,
                                size: 20
                            )
                        }
                    )
                },
                initialSelection: selectedCategoryID,
                onSelectionChange: viewModel.selectCategory
            )
            .padding(.horizontal, Layout.contentHorizontalInset)
            .padding(.bottom, Layout.categoriesBottomInset)
        }
    }

    @ViewBuilder
    var itemsSection: some View {
        switch viewModel.viewState {
        case .loading:
            VStack(spacing: 0) {
                ForEach(0 ..< Layout.skeletonItemCount, id: \.self) { index in
                    skeletonRow(
                        showsDivider: index < Layout.skeletonItemCount - 1
                    )
                }
            }
            .asCellsGroup()
            .padding(.bottom, Layout.itemsBottomInset)
        case let .categories(categories, selectedCategoryID):
            if let category = categories.first(where: { $0.id == selectedCategoryID }) {
                itemsSection(with: category.dataSource)
            } else {
                EmptyView()
            }
        case let .list(dataSource):
            itemsSection(with: dataSource)
        }
    }

    @ViewBuilder
    func itemsSection(
        with dataSource: NetworkFeePickerItemsDataSource
    ) -> some View {
        if !dataSource.items.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(dataSource.items.enumerated()), id: \.element.id) { index, item in
                    FeePickerCell(
                        config: .content(item.feePickerCellContent),
                        showsDivider: index < dataSource.items.count - 1,
                        action: { viewModel.selectItem(item) }
                    )
                }
            }
            .asCellsGroup()
            .padding(.bottom, Layout.itemsBottomInset)
        }
    }

    func skeletonRow(
        showsDivider: Bool
    ) -> some View {
        FeePickerCell(
            config: .shimmer,
            showsDivider: showsDivider
        )
    }
}

private extension NetworkFeePickerItem {
    var feePickerCellContent: FeePickerCellContent {
        FeePickerCellContent(
            leading: feePickerCellLeading,
            title: title,
            subtitle: subtitle,
            badge: feePickerCellBadge
        )
    }

    var title: String {
        switch text {
        case let .singleLine(title), let .titled(title, _):
            title
        }
    }

    var subtitle: String? {
        switch text {
        case .singleLine:
            nil
        case let .titled(_, subtitle):
            subtitle
        }
    }

    var feePickerCellLeading: FeePickerCellContent.Leading {
        switch leading {
        case let .assetAvatar(imageSource):
            return .assetAvatar(imageSource: imageSource)
        case let .icon(image, tintColor, backgroundColor):
            return .icon(
                image: image,
                tintColor: tintColor,
                backgroundColor: backgroundColor
            )
        }
    }

    var feePickerCellBadge: FeePickerCellContent.Badge? {
        guard let badge else {
            return nil
        }

        switch badge {
        case let .accent(text, foreground, background):
            return .init(
                text: text,
                foreground: foreground,
                background: background
            )
        }
    }
}
