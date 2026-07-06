import SwiftUI
import TKLocalize
import TKUIKit

struct TradeAssetDetailsView: View {
    @ObservedObject var viewModel: TradeAssetDetailsViewModel
    @State private var moreButtonAnchorView: UIView?

    enum Section {
        case chart(TokenChartViewState)
        case balance(TradeAssetDetailsBalanceSectionViewData?)
        case history(TradeAssetDetailsHistorySectionViewData)
        case about(TradeAssetDetailsScreenViewData)
        case overview(TradeAssetDetailsScreenViewData)
        case tradingActivity(TradeAssetDetailsTradingActivityViewData)
        case links(TradeAssetDetailsScreenViewData)
    }

    var body: some View {
        ZStack {
            Color(uiColor: .Background.page)
                .ignoresSafeArea()

            if let screen = viewModel.screen {
                VStack(spacing: 0) {
                    headerView
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            tokenAvatarView(shimmer: false)
                            let sections = self.sections(for: screen)
                            ForEach(0 ..< sections.count, id: \.self) { index in
                                let topPadding: CGFloat = if index > 0, case .chart = sections[index - 1] {
                                    Layout.nextSectionToChartTopSpacing
                                } else if case .chart = sections[index] {
                                    Layout.chartTopPadding
                                } else {
                                    Layout.regularSectionTopSpacing
                                }
                                sectionView(for: sections[index])
                                    .padding(.top, topPadding)
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
                .safeAreaInset(edge: .bottom) {
                    if let screen = viewModel.screen {
                        TradeAssetDetailsActionBarView(
                            screen: screen,
                            state: screen.balance == nil ? .buy : .buySell,
                            onBuy: viewModel.handleBuyAction,
                            onSell: viewModel.handleSellAction,
                            onSend: viewModel.handleSendAction,
                            onReceive: viewModel.handleReceiveAction
                        )
                        .padding(.top, Layout.actionsBarTopPadding)
                    }
                }
            } else if viewModel.isLoading {
                VStack(spacing: 0) {
                    headerView
                    tokenAvatarView(shimmer: true)
                    let sections = self.shimmerSections
                    ForEach(0 ..< sections.count, id: \.self) { index in
                        let topPadding: CGFloat = if index > 0, case .chart = sections[index - 1] {
                            Layout.nextSectionToChartTopSpacing
                        } else if case .chart = sections[index] {
                            Layout.chartTopPadding
                        } else {
                            Layout.regularSectionTopSpacing
                        }
                        sectionView(for: sections[index])
                            .padding(.top, topPadding)
                    }
                    Spacer(minLength: 0)
                }
            } else {
                VStack(spacing: 0) {
                    headerView
                    PlaceholderView(
                        config: PlaceholderView.Config(
                            lottieResource: .exclamationmarkCircle,
                            title: TKLocales.Trade.Placeholder.errorTitle,
                            subtitle: viewModel.errorMessage ?? TKLocales.Trade.Placeholder.errorSubtitle,
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
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, Layout.placeholderTopPadding)

                    Spacer(minLength: 0)
                }
            }
        }
    }
}

extension TradeAssetDetailsView {
    @ViewBuilder
    var headerView: some View {
        if let header = viewModel.header {
            DefaultModalCardHeader(
                config: DefaultModalCardHeader.Config(
                    leftIcon: DefaultModalCardHeader.Icon(
                        image: .TKUIKit.Icons.Size16.chevronLeft,
                        size: 16,
                        padding: 8,
                        onTap: { _ in
                            viewModel.goBack()
                        }
                    ),
                    title: DefaultModalCardHeader.Title(
                        text: header.title
                    ),
                    subtitle: header.subtitle
                        .map { subtitle in
                            DefaultModalCardHeader.Subtitle(
                                text: subtitle.title,
                                color: subtitle.color,
                                icon: DefaultModalCardHeader.SubtitleIcon(
                                    image: .TKUIKit.Icons.Size12.informationCircle,
                                    size: 12,
                                    topPadding: 3
                                ),
                                onTap: {
                                    viewModel.handleOpenHeaderSubtitle()
                                }
                            )
                        },
                    rightIcon: DefaultModalCardHeader.Icon(
                        image: .TKUIKit.Icons.Size16.ellipses,
                        size: 16,
                        padding: 8,
                        onTap: { anchor in
                            guard let anchor else {
                                return
                            }
                            TKPopupMenuController.show(
                                sourceView: anchor,
                                position: .bottomRight(inset: 8),
                                minimumWidth: 200,
                                items: [
                                    TKPopupMenuItem(
                                        title: TKLocales.Token.viewDetails,
                                        icon: .TKUIKit.Icons.Size16.globe,
                                        selectionHandler: viewModel.openTokenDetails
                                    ),
                                ],
                                isSelectable: false,
                                selectedIndex: nil
                            )
                        }
                    )
                )
            )
        }
    }

    @ViewBuilder
    func tokenAvatarView(shimmer: Bool) -> some View {
        if let header = viewModel.header {
            HStack(alignment: .top, spacing: 0) {
                AssetAvatarView(
                    imageSource: shimmer
                        ? .shimmer
                        : header.imageSource,
                    size: .regular
                )

                Spacer(minLength: 0)

                if let earnText = header.earnText {
                    Button(action: viewModel.handleOpenEarnAction) {
                        VStack(spacing: 0) {
                            HStack(spacing: 6) {
                                SwiftUI.Image(uiImage: .TKUIKit.Icons.Size16.staking)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(Color(uiColor: .Accent.green))
                                    .frame(width: 16, height: 16)
                                    .padding(.top, 7)
                                    .padding(.leading, 12)
                                Text(earnText)
                                    .textStyle(.label2)
                                    .foregroundStyle(Color(uiColor: .Accent.green))
                                    .padding(.top, 7)
                                    .padding(.trailing, 12)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(height: 32)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color(uiColor: .Accent.green).opacity(0.16))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, Layout.secondaryHorizontalPadding)
            .padding(.trailing, Layout.earnTrailingPadding)
            .padding(.top, Layout.secondaryTopPadding)
        }
    }

    @ViewBuilder
    func sectionView(for section: Section) -> some View {
        switch section {
        case let .chart(chartState):
            TokenChartView(state: chartState)
        case let .balance(balance):
            TradeAssetDetailsBalanceSectionView(
                balance: balance
            )
        case let .history(history):
            TradeAssetDetailsHistorySectionView(
                screen: history,
                onSelectItem: { id in
                    viewModel.openHistoryEvent(id: id)
                },
                onSeeAll: viewModel.openHistory
            )
        case let .about(screen):
            TradeAssetDetailsAboutSectionView(
                screen: screen
            )
        case let .overview(screen):
            TradeAssetDetailsOverviewSectionView(
                screen: screen
            )
        case let .tradingActivity(tradingActivity):
            TradeAssetDetailsTradingActivitySectionView(
                tradingActivity: tradingActivity
            )
        case let .links(screen):
            TradeAssetDetailsLinksSectionView(
                screen: screen,
                onOpenURL: viewModel.open(url:)
            )
        }
    }

    var shimmerSections: [Section] {
        var sections: [Section] = []

        if let chartState = viewModel.chartState {
            sections.append(.chart(chartState))
        }
        sections.append(.balance(nil))

        return sections
    }

    func sections(for screen: TradeAssetDetailsScreenViewData) -> [Section] {
        var sections: [Section] = []

        if let chartState = viewModel.chartState {
            sections.append(.chart(chartState))
        }
        if let balance = screen.balance {
            sections.append(.balance(balance))
        }
        if let history = screen.history {
            sections.append(.history(history))
        }
        sections.append(.about(screen))
        if !screen.overview.isEmpty {
            sections.append(.overview(screen))
        }
        if let tradingActivity = screen.tradingActivity {
            sections.append(.tradingActivity(tradingActivity))
        }
        if !screen.links.isEmpty {
            sections.append(.links(screen))
        }
        return sections
    }
}

private extension TradeAssetDetailsView {
    enum Layout {
        static let chartTopPadding: CGFloat = 14
        static let nextSectionToChartTopSpacing: CGFloat = 3
        static let regularSectionTopSpacing: CGFloat = 16
        static let avatarTopPadding: CGFloat = 16
        static let contentBottomPadding: CGFloat = 20
        static let emptyStateTopPadding: CGFloat = 14
        static let secondaryHorizontalPadding: CGFloat = 24
        static let earnHorizontalPadding: CGFloat = 12
        static let earnTrailingPadding: CGFloat = 20
        static let earnVerticalPadding: CGFloat = 6
        static let secondaryTopPadding: CGFloat = 8
        static let loadingTopPadding: CGFloat = 24
        static let placeholderTopPadding: CGFloat = 152
        static let actionsBarTopPadding: CGFloat = 8
    }
}
