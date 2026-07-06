import SwiftUI
import TKLocalize
import TKUIKit
import UIKit

struct MultichainHistoryView: View {
    @ObservedObject var viewModel: MultichainHistoryViewModelImplementation
    let onClose: () -> Void

    init(
        viewModel: MultichainHistoryViewModelImplementation,
        onClose: @escaping () -> Void = {}
    ) {
        self.viewModel = viewModel
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            Color(uiColor: .Background.page)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                chainTabs
                content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .task {
            viewModel.viewDidLoad()
        }
        .onDisappear {
            viewModel.disappeared()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            typeFilterActionBar
        }
    }
}

private extension MultichainHistoryView {
    var header: some View {
        DefaultModalCardHeader(
            config: DefaultModalCardHeader.Config(
                leftIcon: DefaultModalCardHeader.Icon(
                    image: .TKUIKit.Icons.Size16.chevronLeft,
                    size: 16,
                    padding: 8,
                    onTap: { _ in onClose() }
                ),
                title: DefaultModalCardHeader.Title(
                    text: TKLocales.History.title
                )
            )
        )
    }

    var chainTabs: some View {
        TabCategoriesView(
            items: viewModel.chainTabs.map { tab in
                TabCategoriesView<MultichainHistoryChainFilter>.Item(
                    id: tab.id,
                    title: tab.title,
                    image: tab.image,
                    isSelectable: tab.isSelectable
                )
            },
            initialSelection: viewModel.selectedChainFilter,
            onSelectionChange: { selection in
                viewModel.selectChainFilter(selection)
            },
            insetsModifier: { insets in
                insets.leading = Layout.tabsHorizontalPadding
                insets.trailing = Layout.tabsHorizontalPadding
                insets.bottom = Layout.tabsBottomPadding
            }
        )
        .frame(height: Layout.tabsHeight)
    }

    @ViewBuilder
    var content: some View {
        if let queryViewModel = viewModel.currentQueryViewModel {
            MultichainHistoryContentView(
                viewModel: queryViewModel
            )
        } else {
            MultichainHistorySkeletonView()
        }
    }

    @ViewBuilder
    var typeFilterActionBar: some View {
        if let queryViewModel = viewModel.currentQueryViewModel {
            TypeFilterActionBar(
                viewModel: viewModel,
                queryViewModel: queryViewModel
            )
        }
    }

    struct TypeFilterActionBar: View {
        @ObservedObject var viewModel: MultichainHistoryViewModelImplementation
        @ObservedObject var queryViewModel: MultichainHistoryQueryViewModel
        @State private var typeFilterButtonAnchorView: UIView?

        var body: some View {
            if viewModel.isTypeFilterActionBarVisible(for: queryViewModel) {
                VStack(spacing: 0) {
                    ButtonView(
                        config: ButtonView.Config(
                            title: viewModel.selectedTypeFilterTitle,
                            size: .small,
                            appearance: .tertiary,
                            icon: ButtonView.Icon(
                                image: .TKUIKit.Icons.Size16.switch,
                                alignment: .trailing
                            ),
                            action: showTypeFilterMenu
                        )
                    )
                    .background(
                        AnchorViewResolver { view in
                            typeFilterButtonAnchorView = view
                        }
                    )
                    .padding(.top, Layout.typeFilterActionBarTopPadding)
                    .padding(.bottom, Layout.typeFilterActionBarBottomPadding)
                }
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(
                                color: Color(uiColor: .Background.page).opacity(0),
                                location: 0
                            ),
                            Gradient.Stop(
                                color: Color(uiColor: .Background.page),
                                location: 1
                            ),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .bottom)
                )
            }
        }

        func showTypeFilterMenu() {
            guard let sourceView = typeFilterButtonAnchorView else {
                return
            }

            let items = viewModel.typeFilterItems
            TKPopupMenuController.show(
                sourceView: sourceView,
                position: .top,
                minimumWidth: Layout.typeFilterPopupWidth,
                items: items.enumerated().map { index, item in
                    TKPopupMenuItem(
                        title: item.title,
                        hasSeparator: index + 1 < items.count,
                        selectionHandler: {
                            viewModel.selectTypeFilter(item.id)
                        }
                    )
                },
                selectedIndex: items.firstIndex(where: \.isSelected)
            )
        }
    }

    enum Layout {
        static let tabsHeight: CGFloat = 56
        static let tabsHorizontalPadding: CGFloat = 16
        static let tabsBottomPadding: CGFloat = 16
        static let typeFilterActionBarTopPadding: CGFloat = 32
        static let typeFilterActionBarBottomPadding: CGFloat = 8
        static let typeFilterPopupWidth: CGFloat = 180
    }
}

private struct MultichainHistoryContentView: View {
    @ObservedObject var viewModel: MultichainHistoryQueryViewModel

    var body: some View {
        let presentation = viewModel.presentation

        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if presentation.showsSkeleton {
                    MultichainHistorySkeletonView()
                } else if let placeholder = presentation.placeholder {
                    placeholderView(placeholder)
                } else {
                    sectionsView(presentation.sections)
                    if presentation.isLoadingMore {
                        loadingMoreView
                    }
                }
            }
        }
        .refreshable {
            await Task {
                await MinimumRefreshDurationBehavior.perform {
                    await viewModel.refresh()
                }
            }.value
        }
    }
}

private extension MultichainHistoryContentView {
    func sectionsView(_ sections: [MultichainHistorySection]) -> some View {
        ForEach(sections) { section in
            VStack(alignment: .leading, spacing: 0) {
                ListTitleView(
                    config: .text(section.title)
                )
                .padding(.horizontal, Layout.horizontalPadding)

                LazyVStack(spacing: Layout.cellSpacing) {
                    ForEach(section.items) { item in
                        transactionCell(item)
                            .onAppear {
                                viewModel.loadNextPageIfNeeded(currentItem: item)
                            }
                    }
                }

                Spacer()
                    .frame(height: Layout.sectionSpacing)
            }
        }
    }

    func transactionCell(_ item: MultichainHistoryActivityItem) -> some View {
        TransactionCell(
            config: .content(
                TransactionCellContent(
                    icon: item.transactionIcon,
                    title: item.title,
                    subtitle: TransactionCellContent.Subtitle(
                        text: item.subtitle ?? "",
                        style: .primary
                    ),
                    amount: item.transactionAmount,
                    accessory: item.transactionAccessory,
                    details: item.transactionDetails
                )
            )
        )
        .asCellsGroup()
    }

    func placeholderView(_ placeholder: MultichainHistoryQueryViewModel.Placeholder) -> some View {
        VStack(spacing: 0) {
            PlaceholderView(
                config: placeholderConfig(placeholder)
            )
            Spacer(minLength: 0)
        }
        .padding(.top, Layout.placeholderTopPadding)
        .frame(maxWidth: .infinity)
    }

    func placeholderConfig(_ placeholder: MultichainHistoryQueryViewModel.Placeholder) -> PlaceholderView.Config {
        switch placeholder {
        case .empty:
            return PlaceholderView.Config(
                lottieResource: .clock,
                title: TKLocales.MultichainHistory.Placeholder.title,
                subtitle: TKLocales.MultichainHistory.Placeholder.subtitle,
                button: PlaceholderView.ButtonConfig(
                    title: TKLocales.MultichainHistory.Placeholder.Buttons.addFunds,
                    action: viewModel.addFunds
                )
            )
        case let .error(message):
            return PlaceholderView.Config(
                lottieResource: .exclamationmarkCircle,
                title: TKLocales.Trade.Placeholder.errorTitle,
                subtitle: message ?? TKLocales.Trade.Placeholder.errorSubtitle,
                button: PlaceholderView.ButtonConfig(
                    title: TKLocales.Actions.retry,
                    icon: .TKUIKit.Icons.Size16.refresh,
                    action: {
                        Task {
                            await viewModel.refresh()
                        }
                    }
                )
            )
        }
    }

    var loadingMoreView: some View {
        ProgressView()
            .tint(Color(uiColor: .Accent.blue))
            .frame(maxWidth: .infinity)
            .frame(height: Layout.loadingMoreHeight)
    }

    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let cellSpacing: CGFloat = 8
        static let sectionSpacing: CGFloat = 16
        static let bottomPadding: CGFloat = 16
        static let placeholderTopPadding: CGFloat = 139
        static let loadingMoreHeight: CGFloat = 56
    }
}

private struct MultichainHistorySkeletonView: View {
    private let rows = Array(0 ..< 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ListTitleView(config: .shimmer)
                .padding(.horizontal, Layout.horizontalPadding)

            LazyVStack(spacing: Layout.cellSpacing) {
                ForEach(rows, id: \.self) { _ in
                    TransactionCell(config: .shimmer)
                        .asCellsGroup()
                }
            }
        }
    }
}

private extension MultichainHistorySkeletonView {
    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let cellSpacing: CGFloat = 8
    }
}

private extension MultichainHistoryActivityItem {
    var transactionIcon: TransactionCellContent.Icon {
        TransactionCellContent.Icon(
            image: icon,
            tintColor: Color(uiColor: .Icon.secondary)
        )
    }

    var transactionAmount: TransactionCellContent.Amount {
        TransactionCellContent.Amount(
            title: primaryAmount?.text ?? "-",
            style: primaryAmount.map(\.transactionAmountStyle) ?? .tertiary
        )
    }

    var transactionAccessory: TransactionCellContent.Accessory {
        guard let secondaryAmount else {
            return TransactionCellContent.Accessory(text: time)
        }

        return TransactionCellContent.Accessory(
            text: secondaryAmount.text,
            textStyle: .label1,
            color: secondaryAmount.transactionAccessoryColor
        )
    }

    var transactionDetails: TransactionCellContent.Details? {
        guard secondaryAmount != nil else {
            return nil
        }

        return TransactionCellContent.Details(
            accessory: TransactionCellContent.DetailsAccessory(
                text: time
            )
        )
    }
}

private extension MultichainHistoryActivityItem.Amount {
    var transactionAmountStyle: TransactionCellContent.AmountStyle {
        switch style {
        case .primary:
            return .primary
        case .positive:
            return .positive
        case .negative:
            return .primary
        }
    }

    var transactionAccessoryColor: Color {
        switch style {
        case .positive:
            return Color(uiColor: .Accent.green)
        case .primary, .negative:
            return Color(uiColor: .Text.primary)
        }
    }
}
