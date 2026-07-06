import KeeperCore
import TKCoordinator
import TKCore
import TKLocalize
import TKLogging
import TKUIKit
import TonSwift
import UIKit

final class TradeCoordinator: RouterCoordinator<NavigationControllerRouter> {
    private let coreAssembly: TKCore.CoreAssembly
    private let keeperCoreMainAssembly: KeeperCore.MainAssembly
    private let analyticsProvider: AnalyticsProvider
    private let amountFormatter: AmountFormatter
    private let shelvesService: TradingShelvesService
    private let assetsListService: TradingAssetsListService
    private let assetDetailsService: TradingAssetDetailsService
    private let balanceService: BalanceService
    private let ratesService: RatesService
    private let jettonService: JettonService
    private let currencyStore: CurrencyStore
    private let signedAmountFormatter: AmountFormatter
    private let chartViewStateProvider: (String) -> TokenChartViewState?
    private let output: TradeModule.CoordinatorOutput
    private weak var shelvesViewController: TradeViewController?

    init(
        router: NavigationControllerRouter,
        coreAssembly: TKCore.CoreAssembly,
        keeperCoreMainAssembly: KeeperCore.MainAssembly,
        jettonService: JettonService,
        shelvesService: TradingShelvesService,
        assetsListService: TradingAssetsListService,
        assetDetailsService: TradingAssetDetailsService,
        balanceService: BalanceService,
        ratesService: RatesService,
        currencyStore: CurrencyStore,
        amountFormatter: AmountFormatter,
        signedAmountFormatter: AmountFormatter,
        chartViewStateProvider: @escaping (String) -> TokenChartViewState?,
        output: TradeModule.CoordinatorOutput
    ) {
        self.coreAssembly = coreAssembly
        self.keeperCoreMainAssembly = keeperCoreMainAssembly
        self.analyticsProvider = coreAssembly.analyticsProvider
        self.amountFormatter = amountFormatter
        self.signedAmountFormatter = signedAmountFormatter
        self.shelvesService = shelvesService
        self.assetsListService = assetsListService
        self.assetDetailsService = assetDetailsService
        self.jettonService = jettonService
        self.balanceService = balanceService
        self.ratesService = ratesService
        self.currencyStore = currencyStore
        self.chartViewStateProvider = chartViewStateProvider
        self.output = output
        super.init(router: router)
        router.rootViewController.tabBarItem.title = TKLocales.Tabs.trade
        router.rootViewController.tabBarItem.image = .TKUIKit.Icons.Size28.trade
    }

    override func start() {
        openShelves(tradeFlowAnalyticsSource: .tabBar)
    }
}

extension TradeCoordinator {
    func openRoot(animated: Bool) {
        router.rootViewController.popToRootViewController(animated: animated)
    }

    func scrollToGrid(id: String) {
        shelvesViewController?.scrollToGrid(id: id)
    }

    func openShelves(
        tradeFlowAnalyticsSource: TradeFlowAnalyticsSource
    ) {
        let viewModel = TradeViewModel(
            analyticsProvider: analyticsProvider,
            analyticsSource: tradeFlowAnalyticsSource,
            shelvesService: shelvesService,
            amountFormatter: amountFormatter,
            signedAmountFormatter: signedAmountFormatter,
            onOpenAssetList: { [weak self] category in
                guard let self else { return }
                openAssetList(
                    initialCategory: category,
                    tradeFlowAnalyticsSource: tradeFlowAnalyticsSource
                )
            },
            onOpenAssetDetails: { [weak self] asset in
                guard let self else { return }
                self.openAssetDetails(
                    preview: self.makePreviewContext(
                        assetID: asset.id,
                        assetCategory: asset.category,
                        title: asset.name,
                        imageURL: asset.imageURL,
                        symbol: asset.symbol,
                        isUnverified: asset.isUnverified
                    ),
                    on: self.router.rootViewController,
                    source: .tradeScreen
                )
            }
        )
        let viewController = TradeViewController(viewModel: viewModel)
        shelvesViewController = viewController
        router.push(viewController: viewController, animated: false)
    }

    func openAssetList(
        initialCategory: TradingAssetCategory,
        tradeFlowAnalyticsSource: TradeFlowAnalyticsSource,
        on presentingViewController: UIViewController? = nil
    ) {
        let navigationController = TKNavigationController()
        navigationController.configureTransparentAppearance()
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.modalPresentationStyle = .fullScreen
        let assetDetailsSource = tradeFlowAnalyticsSource.assetViewSource

        let viewController = TradeAssetsListViewController(
            viewModel: TradeAssetsListViewModel(
                analyticsProvider: analyticsProvider,
                analyticsSource: tradeFlowAnalyticsSource,
                assetsListService: assetsListService,
                amountFormatter: amountFormatter,
                signedAmountFormatter: signedAmountFormatter,
                selectedCategory: initialCategory,
                onClose: { [weak navigationController] in
                    navigationController?.dismiss(animated: true)
                },
                onOpenAssetDetails: { [weak self, weak navigationController] asset in
                    guard let self else { return }
                    self.openAssetDetails(
                        preview: self.makePreviewContext(
                            assetID: asset.id,
                            assetCategory: asset.category,
                            title: asset.subtitle,
                            imageURL: asset.imageURL,
                            symbol: asset.symbol,
                            isUnverified: asset.isUnverified
                        ),
                        on: navigationController,
                        source: assetDetailsSource
                    )
                }
            )
        )
        navigationController.setViewControllers([viewController], animated: false)
        presentAssetList(navigationController, on: presentingViewController)
    }

    func openAssetDetails(
        preview: TradeAssetDetailsViewModel.PreviewContext,
        on navigationController: UINavigationController?,
        source: AssetViewAnalyticsSource
    ) {
        guard let wallet = activeWallet() else {
            return
        }
        let isRootTradeNavigation = navigationController === router.rootViewController
        let typedAssetId = TradingAssetToken(assetId: preview.assetID)

        let viewController = TradeAssetDetailsViewController(
            viewModel: TradeAssetDetailsViewModel(
                preview: preview,
                analyticsProvider: analyticsProvider,
                analyticsSource: source,
                assetDetailsService: assetDetailsService,
                currencyStore: currencyStore,
                amountFormatter: amountFormatter,
                signedAmountFormatter: signedAmountFormatter,
                tokenDetailsConfiguratorProvider: { [weak self] assetInfo in
                    guard
                        let self,
                        let wallet = activeWallet(),
                        let token = await token(for: assetInfo, wallet: wallet)
                    else {
                        return nil
                    }
                    return output.tokenDetailsConfiguratorProvider(wallet, token)
                },
                marketDataViewModel: TradeAssetDetailsMarketDataViewModel(
                    typedAssetId: typedAssetId,
                    ratesService: ratesService,
                    currencyStore: currencyStore,
                    amountFormatter: amountFormatter,
                    signedAmountFormatter: signedAmountFormatter
                ),
                balanceViewModel: TradeAssetDetailsBalanceViewModel(
                    wallet: wallet,
                    typedAssetId: typedAssetId,
                    balanceLoader: keeperCoreMainAssembly.loadersAssembly.balanceLoader,
                    convertedBalanceStore: keeperCoreMainAssembly.storesAssembly.convertedBalanceStore
                ),
                historyViewModel: TradeAssetDetailsHistoryViewModel(
                    wallet: wallet,
                    typedAssetId: typedAssetId,
                    historyService: keeperCoreMainAssembly.servicesAssembly.historyService(),
                    tronUSDTHistoryService: keeperCoreMainAssembly.servicesAssembly.tronUSDTHistoryService(),
                    tronUsdtApi: keeperCoreMainAssembly.servicesAssembly.tronUsdtApi(),
                    tonProofTokenService: keeperCoreMainAssembly.servicesAssembly.tonProofTokenService(),
                    accountEventMapper: keeperCoreMainAssembly.mappersAssembly.historyAccountEventMapper,
                    dateFormatter: keeperCoreMainAssembly.formattersAssembly.dateFormatter,
                    signedAmountFormatter: signedAmountFormatter,
                    walletNFTsManagementStoreProvider: { [keeperCoreMainAssembly] wallet in
                        keeperCoreMainAssembly.storesAssembly.walletNFTsManagementStore(wallet: wallet)
                    },
                    backgroundUpdate: keeperCoreMainAssembly.backgroundUpdateAssembly.backgroundUpdate
                ),
                tonStakingAPYProvider: { [keeperCoreMainAssembly] in
                    let configuration = keeperCoreMainAssembly.configurationAssembly.configuration
                    guard !configuration.flag(\.stakingDisabled, network: wallet.network) else {
                        return nil
                    }

                    return keeperCoreMainAssembly.storesAssembly.stackingPoolsStore.state[wallet]?
                        .filter { configuration.value(\.stakingEnabledProviders).contains($0.implementation.type.rawValue) }
                        .map(\.apy)
                        .max()
                },
                onOpenUrl: { [weak self, weak navigationController] url in
                    guard let self else { return }
                    output.onOpenUrl(url, navigationController)
                },
                chartStateProvider: chartViewStateProvider,
                onOpenHistory: { [weak self, weak navigationController] context in
                    guard let self else { return }
                    openAssetHistory(
                        context: context,
                        on: navigationController
                    )
                },
                onOpenHistoryEvent: { [weak self, weak navigationController] selection in
                    guard let self else { return }
                    output.onOpenHistoryEvent(selection, navigationController)
                },
                onBuy: { [weak self, weak navigationController] assetInfo in
                    guard let wallet = self?.activeWallet() else {
                        return
                    }
                    Task { @MainActor [weak self] in
                        guard
                            let self,
                            let token = await token(for: assetInfo, wallet: wallet)
                        else {
                            return
                        }
                        await openTradeAssetSwap(
                            wallet: wallet,
                            token: token,
                            tokenCategory: assetInfo.category,
                            direction: .buy,
                            navigationController: navigationController
                        )
                    }
                },
                onSell: { [weak self, weak navigationController] assetInfo in
                    guard let wallet = self?.activeWallet() else {
                        return
                    }
                    Task { @MainActor [weak self] in
                        guard
                            let self,
                            let token = await token(for: assetInfo, wallet: wallet)
                        else {
                            return
                        }
                        await openTradeAssetSwap(
                            wallet: wallet,
                            token: token,
                            tokenCategory: assetInfo.category,
                            direction: .sell,
                            navigationController: navigationController
                        )
                    }
                },
                onSend: { [weak self, weak navigationController] assetInfo in
                    guard let wallet = self?.activeWallet() else {
                        return
                    }
                    Task { @MainActor [weak self] in
                        guard
                            let self,
                            let token = await token(for: assetInfo, wallet: wallet)
                        else {
                            return
                        }
                        output.onSend(wallet, token, navigationController)
                    }
                },
                onReceive: { [weak self, weak navigationController] assetInfo in
                    guard let wallet = self?.activeWallet() else {
                        return
                    }
                    Task { @MainActor [weak self] in
                        guard
                            let self,
                            let token = await token(for: assetInfo, wallet: wallet)
                        else {
                            return
                        }
                        output.onReceive([token], wallet, navigationController)
                    }
                },
                onOpenStaking: { [output] in
                    output.onOpenStaking(wallet)
                },
                onOpenTokenizedInfo: { [weak self] kind in
                    guard let self else { return }
                    openTokenizedAssetInfoPopup(kind: kind)
                },
                onOpenUnverifiedTokenInfo: { [output, weak navigationController] in
                    output.onOpenUnverifiedTokenInfoPopup(navigationController)
                },
                onBack: { [weak self, weak navigationController] in
                    if isRootTradeNavigation {
                        self?.router.pop(animated: true)
                    } else {
                        navigationController?.popViewController(animated: true)
                    }
                }
            )
        )

        viewController.hidesBottomBarWhenPushed = isRootTradeNavigation

        if isRootTradeNavigation {
            router.push(viewController: viewController, animated: true)
        } else {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    func openAssetDetails(
        assetID: String,
        source: AssetViewAnalyticsSource
    ) {
        openAssetDetails(
            preview: makePreviewContext(assetID: assetID),
            on: router.rootViewController,
            source: source
        )
    }

    func openAssetHistory(
        context: TradeAssetHistoryContext,
        on navigationController: UINavigationController?
    ) {
        let presentingNavigationController = navigationController ?? router.rootViewController
        let module = historyListModule(for: context)

        module.view.title = TKLocales.Trade.AssetDetails.History.title
        module.view.navigationItem.largeTitleDisplayMode = .never
        module.view.adjustsContentTopPaddingToNavigationBar = true

        let modalNavigationController = TKNavigationController(rootViewController: module.view)
        module.view.setupRightCloseButton { [weak modalNavigationController] in
            modalNavigationController?.dismiss(animated: true)
        }
        modalNavigationController.configureDefaultAppearance(separatorHidden: true)
        modalNavigationController.navigationBar.prefersLargeTitles = false
        if #available(iOS 15.0, *) {
            modalNavigationController.navigationBar.scrollEdgeAppearance = modalNavigationController.navigationBar.standardAppearance
        }
        modalNavigationController.setNavigationBarHidden(false, animated: false)
        modalNavigationController.modalPresentationStyle = .automatic

        module.output.didSelectEvent = { [weak self] event in
            guard let self else {
                return
            }
            switch event {
            case let .tonEvent(event):
                output.onOpenHistoryEvent(
                    .ton(wallet: wallet(for: context), event: event),
                    modalNavigationController
                )
            case let .tronEvent(event):
                output.onOpenHistoryEvent(
                    .tron(wallet: wallet(for: context), event: event),
                    modalNavigationController
                )
            }
        }

        presentingNavigationController.present(modalNavigationController, animated: true)
    }
}

private extension TradeCoordinator {
    func presentAssetList(
        _ navigationController: UINavigationController,
        on presentingViewController: UIViewController?
    ) {
        if let presentingViewController {
            presentingViewController.topPresentedViewController().present(navigationController, animated: true)
        } else {
            router.present(navigationController)
        }
    }

    func makePreviewContext(
        assetID: String,
        assetCategory: TradingAssetCategory?,
        title: String,
        imageURL: URL?,
        symbol: String,
        isUnverified: Bool?
    ) -> TradeAssetDetailsViewModel.PreviewContext {
        .init(
            assetID: assetID,
            assetCategory: assetCategory,
            title: title,
            imageURL: imageURL,
            isUnverified: isUnverified
        )
    }

    func makePreviewContext(assetID: String) -> TradeAssetDetailsViewModel.PreviewContext {
        return .init(
            assetID: assetID,
            assetCategory: TradingAssetCategory(assetID: assetID),
            title: nil,
            imageURL: nil,
            isUnverified: nil
        )
    }
}

private extension TradeCoordinator {
    func activeWallet() -> Wallet? {
        try? keeperCoreMainAssembly.storesAssembly.walletsStore.activeWallet
    }

    func token(for assetInfo: TradingAssetInfo, wallet: Wallet) async -> Token? {
        await token(for: assetInfo.typedAssetId, wallet: wallet)
    }

    func token(for tradeAssetBalanceIdentifier: TradingAssetToken?, wallet: Wallet) async -> Token? {
        switch tradeAssetBalanceIdentifier {
        case .ton:
            return .ton(.ton)
        case .tronUsdt:
            return .tron(.usdt)
        case let .jetton(address):
            if let walletBalance = try? balanceService.getBalance(wallet: wallet),
               let jettonItem = walletBalance.balance.jettonsBalance.first(where: {
                   $0.item.jettonInfo.address == address
               })?.item
            {
                return .ton(.jetton(jettonItem))
            }

            return await Task { @MainActor in
                ToastPresenter.showToast(configuration: .loading)
                let token: Token
                do {
                    token = try await .ton(
                        .jetton(
                            JettonItem(
                                jettonInfo: jettonService.jettonInfo(
                                    address: address,
                                    network: wallet.network
                                ),
                                walletAddress: nil
                            )
                        )
                    )
                    ToastPresenter.hideToast()
                } catch {
                    Log.w("failed to resolve jetton info due to error: \(error.localizedDescription)")
                    ToastPresenter.hideToast()
                    ToastPresenter.showToast(
                        configuration: ToastPresenter.Configuration(
                            title: TKLocales.Trade.Assets.Errors.load
                        )
                    )
                    return nil
                }
                return token
            }.value
        case nil:
            await MainActor.run {
                ToastPresenter.showToast(
                    configuration: ToastPresenter.Configuration(
                        title: TKLocales.Trade.Assets.Errors.load
                    )
                )
            }
            return nil
        }
    }

    func historyListModule(
        for context: TradeAssetHistoryContext
    ) -> MVVMModule<HistoryListViewController, HistoryListModuleOutput, HistoryListModuleInput> {
        let historyModule = HistoryModule(
            dependencies: HistoryModule.Dependencies(
                coreAssembly: coreAssembly,
                keeperCoreMainAssembly: keeperCoreMainAssembly
            )
        )
        switch context {
        case let .ton(wallet):
            return historyModule.createTonHistoryListModule(wallet: wallet)
        case let .jetton(wallet, jettonMasterAddress):
            return historyModule.createJettonHistoryListModule(
                jettonMasterAddress: jettonMasterAddress,
                wallet: wallet
            )
        case let .tronUSDT(wallet):
            return historyModule.createTronUSDTHistoryListModule(wallet: wallet)
        }
    }

    func wallet(for context: TradeAssetHistoryContext) -> Wallet {
        switch context {
        case let .ton(wallet), let .tronUSDT(wallet), let .jetton(wallet, _):
            return wallet
        }
    }

    func openTokenizedAssetInfoPopup(kind: TokenizedAssetInfoKind) {
        AssetInfoPopupPresenter.presentTokenized(
            kind: kind,
            from: router.rootViewController.topPresentedViewController()
        )
    }

    private func getPasscode() async -> String? {
        await PasscodeInputCoordinator.getPasscode(
            parentCoordinator: self,
            parentRouter: router,
            mnemonicAccess: keeperCoreMainAssembly.secureAssembly.mnemonicAccess,
            securityStore: keeperCoreMainAssembly.storesAssembly.securityStore
        )
    }

    private enum TradeAssetSwapDirection {
        case buy
        case sell
    }

    private func openTradeAssetSwap(
        wallet: Wallet,
        token: Token,
        tokenCategory: TradingAssetCategory,
        direction: TradeAssetSwapDirection,
        navigationController: UINavigationController?
    ) async {
        switch token {
        case let .ton(tonToken):
            let fromToken: TonToken
            let toToken: TonToken
            let fromCategory: TradingAssetCategory
            let toCategory: TradingAssetCategory
            switch tonToken {
            case .ton:
                guard
                    let usdtAnyToken = await self.token(for: .jetton(JettonMasterAddress.tonUSDT), wallet: wallet)
                else {
                    return
                }
                guard case let .ton(usdt) = usdtAnyToken else {
                    return output.onSwap(
                        .tron,
                        wallet,
                        navigationController
                    )
                }
                switch direction {
                case .buy:
                    fromToken = usdt
                    toToken = .ton
                    fromCategory = .crypto
                    toCategory = .crypto
                case .sell:
                    fromToken = .ton
                    toToken = usdt
                    fromCategory = .crypto
                    toCategory = .crypto
                }
            case let .jetton(item):
                let counterpartToken: TonToken
                if item.jettonInfo.address == JettonMasterAddress.SPYx {
                    counterpartToken = .ton
                } else if tokenCategory.requiresUSDTNativeSwapCounterpart {
                    guard
                        let usdtAnyToken = await self.token(for: .jetton(JettonMasterAddress.tonUSDT), wallet: wallet),
                        case let .ton(usdt) = usdtAnyToken
                    else {
                        return
                    }
                    counterpartToken = usdt
                } else {
                    counterpartToken = .ton
                }
                switch direction {
                case .buy:
                    fromToken = counterpartToken
                    toToken = .jetton(item)
                    fromCategory = .crypto
                    toCategory = tokenCategory
                case .sell:
                    fromToken = .jetton(item)
                    toToken = counterpartToken
                    fromCategory = tokenCategory
                    toCategory = .crypto
                }
            }
            output.onSwap(
                .ton(
                    from: fromToken,
                    to: toToken,
                    fromCategory: fromCategory,
                    toCategory: toCategory
                ),
                wallet,
                navigationController
            )
        case .tron:
            output.onSwap(
                .tron,
                wallet,
                navigationController
            )
        }
    }
}

private extension TradingAssetCategory {
    var requiresUSDTNativeSwapCounterpart: Bool {
        switch self {
        case .stocks, .etfs:
            return true
        case .all, .crypto:
            return false
        }
    }
}
