import Combine
import Foundation
import KeeperCore
import TKCore
import TKLocalize
import TKUIKit
import UIKit

@MainActor
final class TradeAssetDetailsViewModel: ObservableObject {
    struct PreviewContext {
        let assetID: String
        let assetCategory: TradingAssetCategory?
        let title: String?
        let imageURL: URL?
        let isUnverified: Bool?
    }

    @Published private(set) var header: TradeAssetDetailsHeaderViewData?
    @Published private(set) var screen: TradeAssetDetailsScreenViewData?
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?

    let chartState: TokenChartViewState?

    private let assetID: String
    private let analyticsProvider: AnalyticsProvider
    private let analyticsSource: AssetViewAnalyticsSource
    private let assetDetailsService: TradingAssetDetailsService
    private let mapper: TradeAssetDetailsScreenMapper
    private let marketDataViewModel: TradeAssetDetailsMarketDataViewModel
    private let balanceViewModel: TradeAssetDetailsBalanceViewModel
    private let historyViewModel: TradeAssetDetailsHistoryViewModel
    private let tonStakingAPYProvider: () -> Decimal?
    private let chartStateProvider: (String) -> TokenChartViewState?
    private let tokenDetailsConfiguratorProvider: (TradingAssetInfo) async -> TokenDetailsConfigurator?
    private let onOpenHistory: (TradeAssetHistoryContext) -> Void
    private let onOpenHistoryEvent: (TradeAssetHistorySelection) -> Void
    private let onOpenUrl: (URL) -> Void
    private let onBuy: (TradingAssetInfo) -> Void
    private let onSell: (TradingAssetInfo) -> Void
    private let onSend: (TradingAssetInfo) -> Void
    private let onReceive: (TradingAssetInfo) -> Void
    private let onOpenStaking: () -> Void
    private let onOpenTokenizedInfo: (TokenizedAssetInfoKind) -> Void
    private let onOpenUnverifiedTokenInfo: () -> Void
    private let onBack: () -> Void

    private var hasLoaded = false
    private var details: TradingAssetDetails?
    private var supplementalMarketData: TradeAssetDetailsMarketData?
    private var balanceSnapshot: TradeAssetDetailsBalanceSnapshot?
    private var historyPreview: TradeAssetDetailsHistoryPreview?
    private var cancellables = Set<AnyCancellable>()
    private var transactionSendNotificationToken: NSObjectProtocol?

    init(
        preview: PreviewContext,
        analyticsProvider: AnalyticsProvider,
        analyticsSource: AssetViewAnalyticsSource,
        assetDetailsService: TradingAssetDetailsService,
        currencyStore: CurrencyStore,
        amountFormatter: AmountFormatter,
        signedAmountFormatter: AmountFormatter,
        tokenDetailsConfiguratorProvider: @escaping (TradingAssetInfo) async -> TokenDetailsConfigurator?,
        marketDataViewModel: TradeAssetDetailsMarketDataViewModel,
        balanceViewModel: TradeAssetDetailsBalanceViewModel,
        historyViewModel: TradeAssetDetailsHistoryViewModel,
        tonStakingAPYProvider: @escaping () -> Decimal?,
        onOpenUrl: @escaping (URL) -> Void,
        chartStateProvider: @escaping (String) -> TokenChartViewState?,
        onOpenHistory: @escaping (TradeAssetHistoryContext) -> Void,
        onOpenHistoryEvent: @escaping (TradeAssetHistorySelection) -> Void,
        onBuy: @escaping (TradingAssetInfo) -> Void,
        onSell: @escaping (TradingAssetInfo) -> Void,
        onSend: @escaping (TradingAssetInfo) -> Void,
        onReceive: @escaping (TradingAssetInfo) -> Void,
        onOpenStaking: @escaping () -> Void,
        onOpenTokenizedInfo: @escaping (TokenizedAssetInfoKind) -> Void,
        onOpenUnverifiedTokenInfo: @escaping () -> Void,
        onBack: @escaping () -> Void
    ) {
        self.assetID = preview.assetID
        self.analyticsProvider = analyticsProvider
        self.analyticsSource = analyticsSource
        self.assetDetailsService = assetDetailsService
        let mapper = TradeAssetDetailsScreenMapper(
            preview: preview,
            amountFormatter: amountFormatter,
            signedAmountFormatter: signedAmountFormatter,
            currencyProvider: { [currencyStore] in
                currencyStore.state
            }
        )
        self.mapper = mapper
        self.header = mapper.initialHeader
        self.onOpenUrl = onOpenUrl
        self.tokenDetailsConfiguratorProvider = tokenDetailsConfiguratorProvider
        self.marketDataViewModel = marketDataViewModel
        self.balanceViewModel = balanceViewModel
        self.historyViewModel = historyViewModel
        self.tonStakingAPYProvider = tonStakingAPYProvider
        self.chartStateProvider = chartStateProvider
        self.onOpenHistory = onOpenHistory
        self.onOpenHistoryEvent = onOpenHistoryEvent
        self.onBuy = onBuy
        self.onSell = onSell
        self.onSend = onSend
        self.onReceive = onReceive
        self.onOpenStaking = onOpenStaking
        self.onOpenTokenizedInfo = onOpenTokenizedInfo
        self.onOpenUnverifiedTokenInfo = onOpenUnverifiedTokenInfo
        self.onBack = onBack

        chartState = AssetIdResolver.chartIdentifier(
            for: assetID
        ).flatMap {
            chartStateProvider($0)
        }

        transactionSendNotificationToken = NotificationCenter.default.addObserver(
            forName: .transactionSendNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.hasLoaded else {
                    return
                }
                await self.refresh()
            }
        }

        bindContentViewModels()
    }

    deinit {
        if let transactionSendNotificationToken {
            NotificationCenter.default.removeObserver(transactionSendNotificationToken)
        }
    }

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        analyticsProvider.log(
            AssetView(
                from: analyticsSource.assetView,
                asset: assetID
            )
        )

        Task {
            if let cached = await assetDetailsService.assetDetails(for: assetID) {
                apply(cached)
                scheduleSupplementaryContentUpdate()
            }
            await refresh()
        }
    }

    func handleAppear() {
        guard hasLoaded else {
            return loadIfNeeded()
        }
        Task { [weak self] in
            await self?.refresh()
        }
    }

    func refresh() async {
        isLoading = true
        defer {
            isLoading = false
        }

        do {
            let details = try await assetDetailsService.loadAssetDetails(id: assetID)
            errorMessage = nil
            apply(details)
            scheduleSupplementaryContentUpdate()
        } catch {
            if screen == nil {
                switch error {
                case let .apiError(message):
                    errorMessage = message
                case .networkError:
                    errorMessage = TKLocales.ConnectionStatus.noInternet
                }
            }
        }
    }

    func goBack() {
        onBack()
    }

    func open(url: URL) {
        onOpenUrl(url)
    }

    func openHistory() {
        guard let context = historyPreview?.context else {
            return
        }
        onOpenHistory(context)
    }

    func openHistoryEvent(id: String) {
        guard let selection = historyPreview?.items.first(where: { $0.id == id })?.selection else {
            return
        }
        onOpenHistoryEvent(selection)
    }

    func handleBuyAction() {
        guard let assetInfo = details?.assetInfo else {
            return
        }
        logButtonClick(.buy, assetID: assetInfo.assetId)
        onBuy(assetInfo)
    }

    func handleSellAction() {
        guard let assetInfo = details?.assetInfo else {
            return
        }
        logButtonClick(.sell, assetID: assetInfo.assetId)
        onSell(assetInfo)
    }

    func handleSendAction() {
        guard screen?.isSendAvailable == true, let assetInfo = details?.assetInfo else {
            return
        }
        logButtonClick(.send, assetID: assetInfo.assetId)
        onSend(assetInfo)
    }

    func handleReceiveAction() {
        guard let assetInfo = details?.assetInfo else {
            return
        }
        logButtonClick(.receive, assetID: assetInfo.assetId)
        onReceive(assetInfo)
    }

    func handleOpenHeaderSubtitle() {
        guard let action = header?.subtitle?.action else {
            return
        }

        switch action {
        case let .tokenizedAssetInfo(kind):
            onOpenTokenizedInfo(kind)
        case .unverifiedTokenInfo:
            onOpenUnverifiedTokenInfo()
        }
    }

    func handleOpenEarnAction() {
        guard case .ton? = details?.assetInfo.typedAssetId else {
            return
        }

        onOpenStaking()
    }

    func openTokenDetails() {
        guard let assetInfo = details?.assetInfo else { return }
        Task { [weak self] in
            guard let self else { return }
            let configurator = await tokenDetailsConfiguratorProvider(assetInfo)
            guard let url = configurator?.getDetailsURL() else { return }
            onOpenUrl(url)
        }
    }

    func logButtonClick(
        _ button: AssetButtonClick.Button,
        assetID: String
    ) {
        analyticsProvider.log(
            AssetButtonClick(
                button: button,
                asset: assetID
            )
        )
    }
}

private extension TradeAssetDetailsViewModel {
    func apply(_ details: TradingAssetDetails) {
        var details = details
        if case .ton? = details.assetInfo.typedAssetId {
            details.assetInfo.earnAPY = tonStakingAPYProvider()
        }

        self.details = details
        rebuildScreen()
    }

    func rebuildScreen() {
        let output = mapper.map(
            details: details,
            marketData: supplementalMarketData,
            balance: balanceSnapshot,
            history: historyPreview
        )
        header = output.header
        screen = output.screen
    }

    func scheduleSupplementaryContentUpdate() {
        marketDataViewModel.scheduleUpdate()
        balanceViewModel.scheduleUpdate()
        historyViewModel.scheduleUpdate()
    }

    func bindContentViewModels() {
        Publishers.CombineLatest3(
            marketDataViewModel.$state,
            balanceViewModel.$state,
            historyViewModel.$state
        )
        .sink { [weak self] marketData, balance, history in
            guard let self else {
                return
            }
            self.supplementalMarketData = marketData
            self.balanceSnapshot = balance
            self.historyPreview = history
            guard self.details != nil else {
                return
            }
            self.rebuildScreen()
        }
        .store(in: &cancellables)
    }
}
