import BigInt
import KeeperCore
import SafariServices
import Stories
import TKCoordinator
import TKCore
import TKFeatureFlags
import TKLocalize
import TKLogging
import TKScreenKit
import TKUIKit
import TonSwift
import UIKit

final class MainCoordinator: RouterCoordinator<TabBarControllerRouter> {
    let keeperCoreMainAssembly: KeeperCore.MainAssembly
    let coreAssembly: TKCore.CoreAssembly
    let mainController: KeeperCore.MainController

    private let mainCoordinatorStateManager: MainCoordinatorStateManager
    var mainCoordinatorStoriesController: MainCoordinatorStoriesController?

    private let walletModule: WalletModule
    private let tradeModule: TradeModule
    private let historyModule: HistoryModule
    private let browserModule: BrowserModule
    private let collectiblesModule: CollectiblesModule

    private var walletCoordinator: WalletCoordinator?
    private var tradeCoordinator: TradeCoordinator?
    private var historyCoordinator: HistoryCoordinator?
    var browserCoordinator: BrowserCoordinator?
    private var collectiblesCoordinator: CollectiblesCoordinator?

    weak var walletTransferSignCoordinator: WalletTransferSignCoordinator?
    private weak var addWalletCoordinator: AddWalletCoordinator?
    private weak var sendTokenCoordinator: SendTokenCoordinator?
    private weak var webSwapCoordinator: WebSwapCoordinator?
    private weak var batteryRefillCoordinator: BatteryRefillCoordinator?
    private weak var topUpCoordinator: TopUpCoordinator?
    private weak var stakingCoordinator: StakingCoordinator?
    private weak var stakingStakeCoordinator: StakingStakeCoordinator?
    private weak var stakingUnstakeCoordinator: StakingUnstakeCoordinator?
    private weak var stakingConfirmationCoordinator: StakingConfirmationCoordinator?
    private weak var nativeSwapCoordinator: NativeSwapCoordinator?
    private weak var multichainSwapCoordinator: MultichainSwapCoordinator?

    private let appStateTracker: AppStateTracker
    private let reachabilityTracker: ReachabilityTracker
    let recipientResolver: RecipientResolver
    let insufficientFundsValidator: InsufficientFundsValidator
    private let inAppReviewService: InAppReviewService
    private let cookiesController: KeeperCore.CookiesController

    var deeplinkHandleTask: Task<Void, Never>?

    private var sendTransactionNotificationToken: NSObjectProtocol?

    private var deeplinkRouter: ContainerViewControllerRouter<UIViewController>?

    private let depositPendingTracker: DepositPendingTracker

    init(
        router: TabBarControllerRouter,
        coreAssembly: TKCore.CoreAssembly,
        keeperCoreMainAssembly: KeeperCore.MainAssembly,
        appStateTracker: AppStateTracker,
        reachabilityTracker: ReachabilityTracker,
        recipientResolver: RecipientResolver,
        insufficientFundsValidator: InsufficientFundsValidator,
        inAppReviewService: InAppReviewService,
        depositPendingTracker: DepositPendingTracker
    ) {
        self.coreAssembly = coreAssembly
        self.keeperCoreMainAssembly = keeperCoreMainAssembly
        self.depositPendingTracker = depositPendingTracker
        self.mainController = keeperCoreMainAssembly.mainController()
        self.walletModule = WalletModule(
            dependencies: WalletModule.Dependencies(
                coreAssembly: coreAssembly,
                keeperCoreMainAssembly: keeperCoreMainAssembly
            )
        )
        self.tradeModule = TradeModule(
            dependencies: TradeModule.Dependencies(
                coreAssembly: coreAssembly,
                keeperCoreMainAssembly: keeperCoreMainAssembly
            )
        )
        self.historyModule = HistoryModule(
            dependencies: HistoryModule.Dependencies(
                coreAssembly: coreAssembly,
                keeperCoreMainAssembly: keeperCoreMainAssembly
            )
        )
        self.browserModule = BrowserModule(
            dependencies: BrowserModule.Dependencies(
                coreAssembly: coreAssembly,
                keeperCoreMainAssembly: keeperCoreMainAssembly
            )
        )
        self.collectiblesModule = CollectiblesModule(
            dependencies: CollectiblesModule.Dependencies(
                coreAssembly: coreAssembly,
                keeperCoreMainAssembly: keeperCoreMainAssembly
            )
        )
        self.appStateTracker = appStateTracker
        self.reachabilityTracker = reachabilityTracker
        self.recipientResolver = recipientResolver
        self.insufficientFundsValidator = insufficientFundsValidator
        self.inAppReviewService = inAppReviewService

        self.mainCoordinatorStateManager = MainCoordinatorStateManager(
            walletsStore: keeperCoreMainAssembly.storesAssembly.walletsStore,
            configuration: keeperCoreMainAssembly.configurationAssembly.configuration,
            walletNFTStoreProvider: { wallet in
                keeperCoreMainAssembly.storesAssembly.walletNFTsStore(wallet: wallet, nftService: keeperCoreMainAssembly.servicesAssembly.accountNftService())
            }
        )
        cookiesController = CookiesController(
            walletsStore: keeperCoreMainAssembly.storesAssembly.walletsStore,
            cookiesService: keeperCoreMainAssembly.servicesAssembly.cookiesService(),
            tonConnectAppsStore: keeperCoreMainAssembly.tonConnectAssembly.tonConnectAppsStore
        )
        super.init(router: router)

        mainController.didReceiveTonConnectRequest = { [weak self] request, wallet, app in
            self?.handleTonConnectRequest(request, wallet: wallet, app: app)
        }
        cookiesController.start()
        appStateTracker.addObserver(self)
        reachabilityTracker.addObserver(self)

        sendTransactionNotificationToken = NotificationCenter.default
            .addObserver(forName: .transactionSendNotification, object: nil, queue: .main) { [weak self] notification in
                guard let self else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    openHistory(
                        fromNavigationController: notification.userInfo?[Self.preservePresentedStackKey] as? UINavigationController
                    )
                    if let wallet = notification.userInfo?["wallet"] as? Wallet {
                        Task {
                            await keeperCoreMainAssembly.storesAssembly.walletsStore.makeWalletActive(wallet)
                        }
                    }
                }
            }

        router.didSelectItem = { [weak self] index in
            guard let self else { return }
            let viewControllers = self.router.rootViewController.viewControllers ?? []
            guard viewControllers.count > index else { return }
            let viewController = viewControllers[index]
            playAnimatedTabBarItemIfNeeded(at: index)
            if viewController === self.tradeCoordinator?.router.rootViewController {
                self.coreAssembly.analyticsProvider.log(
                    TradeStarted(from: TradeFlowAnalyticsSource.tabBar.tradeStarted)
                )
                self.coreAssembly.tooltipsAssembly.service.didPerformTooltipTargetAction(id: .tradeTab)
            }
            if viewController === browserCoordinator?.router.rootViewController {
                coreAssembly.analyticsProvider.log(
                    eventKey: .openBrowser
                )
            }
        }

        PushNotificationTapQueue.setHandler { [weak self] userInfo in
            self?.didOpenAppWithPushNotificationTapHandler(userInfo: userInfo)
        }
    }

    deinit {
        if let sendTransactionNotificationToken {
            NotificationCenter.default.removeObserver(sendTransactionNotificationToken)
        }
        PushNotificationTapQueue.clearHandler()
    }

    override func start(deeplink: CoordinatorDeeplink? = nil) {
        setupChildCoordinators()
        setupTabBarTaps()

        mainCoordinatorStateManager.didUpdateState = { [weak self] state in
            self?.handleStateUpdate(state)
        }
        if let state = try? mainCoordinatorStateManager.getState() {
            handleStateUpdate(state)
        }
        mainController.start()
        try? setupTONWalletKitIfNeeded()
        DispatchQueue.main.async {
            _ = self.handleDeeplink(deeplink: deeplink, fromStories: false)
            self.setupStoriesController()
        }

        resolveWalletsByPubkey()
    }

    private func resolveWalletsByPubkey() {
        let wallets = keeperCoreMainAssembly.storesAssembly.walletsStore.wallets
        let walletsResolveService = keeperCoreMainAssembly.servicesAssembly.walletsResolveService()

        walletsResolveService.resolveWalletsByPubkey(wallets)
    }

    func handleDeeplink(deeplink: CoordinatorDeeplink?, fromStories: Bool) -> Bool {
        switch deeplink {
        case let tonkeeperDeeplink as KeeperCore.Deeplink:
            return handleTonkeeperDeeplink(tonkeeperDeeplink, fromStories: fromStories, sendSource: .deepLink)
        case let string as String:
            do {
                let deeplink = try mainController.parseDeeplink(deeplink: string)
                return handleTonkeeperDeeplink(deeplink, fromStories: fromStories, sendSource: .deepLink)
            } catch {
                ToastPresenter.showToast(configuration: .defaultConfiguration(text: error.localizedDescription))
                return false
            }
        default:
            return false
        }
    }

    private func setupStoriesController() {
        let storiesAssembly = Stories.Assembly(
            keeperCoreAssembly: keeperCoreMainAssembly,
            coreAssembly: coreAssembly
        )
        mainCoordinatorStoriesController = MainCoordinatorStoriesController(
            storiesPresenter: storiesAssembly.storiesPresenter(),
            storiesController: storiesAssembly.storiesController()
        )
        mainCoordinatorStoriesController?.fromViewControllerProvider = { [weak self] in self?.router.rootViewController }
        mainCoordinatorStoriesController?.deeplinkAction = { [weak self] in
            _ = self?.handleDeeplink(deeplink: $0, fromStories: true)
        }
        mainCoordinatorStoriesController?.urlAction = { [weak self] in
            self?.openURL($0, title: nil)
        }
    }

    func setupChildCoordinators() {
        let walletCoordinator = walletModule.createWalletCoordinator()
        walletCoordinator.didTapScan = { [weak self] in
            self?.openScan()
        }

        walletCoordinator.didTapWalletButton = { [weak self] in
            self?.openWalletPicker()
        }

        walletCoordinator.didTapSwap = { [weak self] wallet in
            self?.openSwap(wallet: wallet, token: .ton(.ton))
        }

        walletCoordinator.didTapSettingsButton = { [weak self] wallet in
            self?.openSettings(wallet: wallet)
        }

        walletCoordinator.didTapHistoryButton = { [weak self] in
            guard let self else { return }
            coreAssembly.tooltipsAssembly.service.didPerformTooltipTargetAction(id: .newHistoryEntryPoint)
            openHistory()
        }

        walletCoordinator.didSelectTonDetails = { [weak self] in
            self?.openTonDetails(wallet: $0)
        }

        walletCoordinator.didSelectJettonDetails = { [weak self] wallet, jettonItem, hasPrice in
            self?.openJettonDetails(jettonItem: jettonItem, wallet: wallet, hasPrice: hasPrice)
        }

        walletCoordinator.didSelectTronUSDTDetails = { [weak self] wallet in
            self?.openTronUSDTDetails(wallet: wallet)
        }

        walletCoordinator.didSelectEthenaDetails = { [weak self] wallet in
            self?.openEthenaDetails(wallet: wallet)
        }

        walletCoordinator.didSelectStakingItem = { [weak self] wallet, stakingPoolInfo, _ in
            self?.openStakingItemDetails(
                wallet: wallet,
                stakingPoolInfo: stakingPoolInfo
            )
        }

        walletCoordinator.didSelectCollectStakingItem = { [weak self] wallet, stakingPoolInfo, accountStackingInfo in
            self?.openStakingCollect(
                wallet: wallet,
                stakingPoolInfo: stakingPoolInfo,
                accountStackingInfo: accountStackingInfo
            )
        }

        walletCoordinator.didTapDeposit = { [weak self] wallet in
            self?.openRamp(flow: .deposit, wallet: wallet, entrySource: .walletScreen)
        }

        walletCoordinator.didTapWithdraw = { [weak self] wallet in
            self?.openRamp(flow: .withdraw, wallet: wallet, entrySource: .walletScreen)
        }

        walletCoordinator.didTapStake = { [weak self] wallet in
            self?.openStake(wallet: wallet)
        }

        walletCoordinator.didTapBackup = { [weak self] wallet in
            self?.openBackup(wallet: wallet)
        }

        walletCoordinator.didTapBattery = { [weak self] wallet in
            self?.openBattery(
                wallet: wallet
            )
        }

        walletCoordinator.didRequestDeeplinkHandling = { [weak self] deeplink in
            _ = self?.handleTonkeeperDeeplink(deeplink, fromStories: false, sendSource: .deepLink)
        }

        walletCoordinator.didTapOpenCryptoAssets = { [weak self] in
            guard let self, let tradeCoordinator = self.tradeCoordinator else { return }
            tradeCoordinator.openAssetList(
                initialCategory: .crypto,
                tradeFlowAnalyticsSource: .walletScreen,
                on: router.rootViewController
            )
        }

        let tradeCoordinator: TradeCoordinator?
        if keeperCoreMainAssembly.configurationAssembly.configuration.featureEnabled(.tradingUiEnabled) {
            tradeCoordinator = tradeModule.createTradeCoordinator(
                output: TradeModule.CoordinatorOutput(
                    onSwap: { [weak self] swapContext, wallet, navigationController in
                        guard let self else { return }
                        switch swapContext {
                        case let .ton(from, to, fromCategory, toCategory):
                            let configuration = keeperCoreMainAssembly.configurationAssembly.configuration
                            if configuration.flag(\.nativeSwapDisabled, network: wallet.network) {
                                let address: (TonToken) -> String? = {
                                    switch $0 {
                                    case let .jetton(item):
                                        item.jettonInfo.address.toRaw()
                                    case .ton:
                                        nil
                                    }
                                }
                                openWebSwap(
                                    wallet: wallet,
                                    fromToken: address(from),
                                    toToken: address(to),
                                    presentingViewController: navigationController
                                )
                            } else {
                                openNativeSwap(
                                    wallet: wallet,
                                    nativeSwapContext: NativeSwapContext(
                                        from: .prefetched(.ton(from), category: fromCategory),
                                        to: .prefetched(.ton(to), category: toCategory),
                                        transactionSentNotificationPatch: {
                                            $0[Self.preservePresentedStackKey] = navigationController
                                        }
                                    ),
                                    presentingViewController: navigationController
                                )
                            }
                        case .tron:
                            openTRC20Swap()
                        }
                    },
                    onSend: { [weak self] wallet, token, navigationController in
                        guard let self else { return }
                        openSend(
                            wallet: wallet,
                            sendInput: .direct(item: token.sendV3Item),
                            sendSource: .jettonScreen,
                            transactionSentNotificationPatch: {
                                $0[Self.preservePresentedStackKey] = navigationController
                            },
                            comment: nil
                        )
                    },
                    onReceive: { [weak self] tokens, wallet, _ in
                        guard let self else { return }
                        openReceive(tokens: tokens, wallet: wallet)
                    },
                    onOpenStaking: { [weak self] wallet in
                        self?.openStake(wallet: wallet)
                    },
                    onOpenHistoryEvent: { [weak self] event, navigationController in
                        guard let self else { return }
                        switch event {
                        case let .ton(wallet, event):
                            openHistoryEventDetails(
                                wallet: wallet,
                                event: event,
                                network: wallet.network,
                                fromViewController: navigationController
                            )
                        case let .tron(wallet, event):
                            openTronEventDetails(
                                wallet: wallet,
                                event: event,
                                network: wallet.network,
                                fromViewController: navigationController
                            )
                        }
                    },
                    tokenDetailsConfiguratorProvider: { [weak self] wallet, token in
                        self?.makeTokenDetailsConfigurator(
                            wallet: wallet,
                            token: token
                        )
                    },
                    onOpenUnverifiedTokenInfoPopup: { [weak self] _ in
                        guard let self else { return }
                        openUnverifiedTokenInfoPopup()
                    },
                    onOpenUrl: { [weak self] url, navigationController in
                        guard let self else { return }
                        if let navigationController {
                            navigationController.present(
                                bridgeViewController(for: url, title: nil),
                                animated: true
                            )
                        } else {
                            openURL(url, title: nil)
                        }
                    }
                )
            )
        } else {
            tradeCoordinator = nil
        }
        let tradingUiEnabled = keeperCoreMainAssembly
            .configurationAssembly
            .configuration
            .featureEnabled(.tradingUiEnabled)
        let historyCoordinator = tradingUiEnabled ? nil : createHistoryCoordinator()

        let browserCoordinator = browserModule.createBrowserCoordinator()

        browserCoordinator.didHandleDeeplink = { [weak self] deeplink in
            _ = self?.handleTonkeeperDeeplink(deeplink, fromStories: false, sendSource: .deepLink)
        }

        browserCoordinator.didRequestOpenBuySell = { [weak self] wallet in
            self?.openBuy(wallet: wallet)
        }

        let collectiblesCoordinator = collectiblesModule.createCollectiblesCoordinator(parentRouter: router)
        collectiblesCoordinator.didOpenDapp = { url, title in
            self.openDapp(title: title, url: url)
        }
        collectiblesCoordinator.didRequestDeeplinkHandling = { [weak self] deeplink in
            _ = self?.handleTonkeeperDeeplink(deeplink, fromStories: false, sendSource: .deepLink)
        }
        collectiblesCoordinator.didRequestOpenBuySell = { [weak self] isInternalPurchasing, wallet in
            self?.openBuy(wallet: wallet, isInternalPurchasing: isInternalPurchasing)
        }

        self.walletCoordinator = walletCoordinator
        self.tradeCoordinator = tradeCoordinator
        self.historyCoordinator = historyCoordinator
        self.browserCoordinator = browserCoordinator
        self.collectiblesCoordinator = collectiblesCoordinator

        addChild(walletCoordinator)
        tradeCoordinator.flatMap(addChild)
        historyCoordinator.map(addChild)
        addChild(browserCoordinator)
        addChild(collectiblesCoordinator)

        walletCoordinator.start()
        tradeCoordinator?.start()
        historyCoordinator?.start()
        browserCoordinator.start()
        collectiblesCoordinator.start()
    }

    private func makeTronDetailsConfigurator(
        wallet: Wallet
    ) -> TronUSDTTokenDetailsConfigurator {
        let mapper = TokenDetailsMapper(
            amountFormatter: keeperCoreMainAssembly.formattersAssembly.amountFormatter,
            rateConverter: RateConverter()
        )
        let configuration = keeperCoreMainAssembly.configurationAssembly.configuration

        let configurator = TronUSDTTokenDetailsConfigurator(
            wallet: wallet,
            mapper: mapper,
            configuration: configuration,
            feesSnapshotService: keeperCoreMainAssembly.servicesAssembly.tronUSDTFeesService,
            amountFormatter: keeperCoreMainAssembly.formattersAssembly.amountFormatter,
            buySellMethodsService: keeperCoreMainAssembly.buySellAssembly.buySellMethodsService()
        )

        configurator.didTapBanner = { [weak self] snapshot in
            if snapshot.isTRXOnlyRegion {
                self?.openReceive(tokens: [.tron(.trx)], wallet: wallet)
            } else {
                self?.openUsdtFees(wallet: wallet, snapshot: snapshot, reason: .topup)
            }
        }
        configurator.didTapTransfersAvailable = { [weak self] snapshot in
            self?.openUsdtFees(wallet: wallet, snapshot: snapshot, reason: .topup)
        }

        return configurator
    }

    private func makeTokenDetailsConfigurator(
        wallet: Wallet,
        token: Token
    ) -> TokenDetailsConfigurator {
        let mapper = TokenDetailsMapper(
            amountFormatter: keeperCoreMainAssembly.formattersAssembly.amountFormatter,
            rateConverter: RateConverter()
        )
        let configuration = keeperCoreMainAssembly.configurationAssembly.configuration

        switch token {
        case .ton(.ton):
            return TonTokenDetailsConfigurator(
                wallet: wallet,
                mapper: mapper,
                configuration: configuration
            )
        case let .ton(.jetton(jettonItem)):
            return JettonTokenDetailsConfigurator(
                wallet: wallet,
                jettonItem: jettonItem,
                mapper: mapper,
                configuration: configuration,
                onShowUnverifiedTokenInfo: { [weak self] in
                    self?.openUnverifiedTokenInfoPopup()
                }
            )
        case .tron:
            return makeTronDetailsConfigurator(wallet: wallet)
        }
    }

    private func createHistoryCoordinator(navigationController: UINavigationController? = nil) -> HistoryCoordinator {
        let tradingUiEnabled = keeperCoreMainAssembly
            .configurationAssembly
            .configuration
            .featureEnabled(.tradingUiEnabled)
        let fromViewController: UINavigationController?
        if let navigationController {
            fromViewController = navigationController
        } else if tradingUiEnabled {
            fromViewController = router.rootViewController.navigationController
        } else {
            fromViewController = nil
        }

        let historyCoordinator = historyModule.createHistoryCoordinator(
            routerOrNil: {
                guard tradingUiEnabled else {
                    return nil
                }
                return fromViewController
                    .map(NavigationControllerRouter.init(rootViewController:))
            }(),
            presentationStyle: {
                if tradingUiEnabled {
                    HistoryPresentationStyle.push(
                        closeAction: { [weak fromViewController] in
                            fromViewController?.popViewController(animated: true)
                        }
                    )
                } else {
                    HistoryPresentationStyle.modal(closeAction: nil)
                }
            }()
        )
        historyCoordinator.didOpenTonEventDetails = { [weak self] wallet, event, network in
            self?.openHistoryEventDetails(wallet: wallet, event: event, network: network, fromViewController: fromViewController)
        }
        historyCoordinator.didOpenTronEventDetails = { [weak self] wallet, event, network in
            self?.openTronEventDetails(wallet: wallet, event: event, network: network, fromViewController: fromViewController)
        }
        historyCoordinator.didDecryptComment = { [weak self] wallet, payload, eventId in
            self?.decryptComment(wallet: wallet, payload: payload, eventId: eventId)
        }
        historyCoordinator.didOpenDapp = { [weak self] url, title in
            self?.openDapp(title: title, url: url)
        }
        historyCoordinator.didOpenBuySellItem = { [weak self] url, fromViewController in
            self?.openBuySellItemURL(url, fromViewController: fromViewController)
        }
        historyCoordinator.passcodeProvider = getPasscode

        return historyCoordinator
    }

    func handleStateUpdate(_ state: MainCoordinatorStateManager.State) {
        let viewControllers = state.tabs.compactMap { tab -> RouterCoordinator<NavigationControllerRouter>? in
            switch tab {
            case .wallet:
                walletCoordinator
            case .history:
                historyCoordinator
            case .trade:
                tradeCoordinator
            case .browser:
                browserCoordinator
            case .purchases:
                collectiblesCoordinator
            }
        }.map { $0.router.rootViewController }

        router.rootViewController.setViewControllers(viewControllers, animated: false)
        setupAnimatedTabsIfNeeded(with: state)
        DispatchQueue.main.async { [weak self] in
            self?.showEntryPointTooltipsIfNeeded(with: state)
        }
    }

    @MainActor
    private func setupAnimatedTabsIfNeeded(with state: MainCoordinatorStateManager.State) {
        let tradingUiEnabled = keeperCoreMainAssembly
            .configurationAssembly
            .configuration
            .featureEnabled(.tradingUiEnabled)
        guard tradingUiEnabled else {
            return
        }
        router.rootViewController.configureAnimatedTabBarItems(
            items: state.tabs
        )
    }

    func setupTabBarTaps() {
        (router.rootViewController as? TKTabBarController)?.didLongPressTabBarItem = { [weak self] index in
            guard index == 0 else { return }
            self?.openWalletPicker()
        }
    }

    @MainActor
    private func showEntryPointTooltipsIfNeeded(with state: MainCoordinatorStateManager.State) {
        showNewHistoryEntryPointTooltipIfNeeded()
        showTradeTabTooltipIfNeeded(with: state)
    }

    @MainActor
    private func showNewHistoryEntryPointTooltipIfNeeded() {
        guard let sourceView = walletCoordinator?.historyButtonTooltipSourceView else {
            return
        }

        coreAssembly.tooltipsAssembly.service.showTooltipIfNeeded(
            id: .newHistoryEntryPoint,
            sourceView: sourceView,
            targetActionViews: [sourceView],
            configuration: HintConfiguration(
                position: HintPosition(
                    tailParameters: TKTooltipView.tailParameters,
                    horizontal: .default,
                    vertical: .init(absolute: 0),
                    direction: .bottomRight
                ),
                maximumWidth: 280,
                animationStyle: .bouncing
            )
        )
    }

    @MainActor
    private func showTradeTabTooltipIfNeeded(with state: MainCoordinatorStateManager.State) {
        guard let tradeIndex = state.tabs.firstIndex(of: .trade) else { return }

        router.rootViewController.tabBar.layoutIfNeeded()

        guard let sourceView = router.rootViewController.tabBar.items?[safe: tradeIndex]?.contentView else {
            return
        }

        coreAssembly.tooltipsAssembly.service.showTooltipIfNeeded(
            id: .tradeTab,
            sourceView: sourceView,
            targetActionViews: [sourceView],
            configuration: HintConfiguration(
                position: HintPosition(
                    tailParameters: TKTooltipView.tailParameters,
                    horizontal: .default,
                    vertical: .init(absolute: 0),
                    direction: .topRight
                ),
                maximumWidth: 280,
                animationStyle: .bouncing
            )
        )
    }

    func openScan() {
        let extensions = keeperCoreMainAssembly.configurationAssembly.configuration.value(\.qrScannerExtensions)
        let scanModule = ScannerModule(
            dependencies: ScannerModule.Dependencies(
                coreAssembly: coreAssembly,
                scannerAssembly: keeperCoreMainAssembly.scannerAssembly()
            )
        ).createScannerModule(
            configurator: DefaultScannerControllerConfigurator(extensions: extensions ?? []),
            uiConfiguration: ScannerUIConfiguration(
                title: TKLocales.Scanner.title,
                subtitle: nil,
                isFlashlightVisible: true
            )
        )

        let navigationController = TKNavigationController(rootViewController: scanModule.view)
        navigationController.configureTransparentAppearance()

        scanModule.output.didScanDeeplink = { [weak self] deeplink in
            self?.router.dismiss(completion: {
                _ = self?.handleTonkeeperDeeplink(
                    deeplink,
                    fromStories: false,
                    sendSource: .qrCode
                )
            })
        }

        scanModule.output.didFailScan = { [weak self] error, shouldDismiss in
            ToastPresenter.hideAll()
            guard let error else { return }
            ToastPresenter.showToast(configuration: .init(title: error))
            if shouldDismiss {
                self?.router.dismiss()
            }
        }

        router.present(navigationController)
    }

    func openSend(
        wallet: Wallet,
        sendInput: SendInput,
        sendSource: SendAnalyticsSource,
        transactionSentNotificationPatch: @Sendable @escaping (inout [String: Any]) -> Void = { _ in },
        recipient: Recipient? = nil,
        comment: String?,
        successReturn: URL? = nil
    ) {
        let navigationController = TKNavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)

        let sendTokenCoordinator = SendModule(
            dependencies: SendModule.Dependencies(
                coreAssembly: coreAssembly,
                keeperCoreMainAssembly: keeperCoreMainAssembly
            )
        ).createSendTokenCoordinator(
            router: NavigationControllerRouter(rootViewController: navigationController),
            wallet: wallet,
            sendInput: sendInput,
            sendSource: sendSource,
            transactionSentNotificationPatch: transactionSentNotificationPatch,
            recipient: recipient,
            comment: comment
        )

        sendTokenCoordinator.didFinish = { [weak self, weak navigationController] in
            self?.sendTokenCoordinator = nil
            navigationController?.dismiss(animated: true)
            self?.removeChild($0)
        }

        sendTokenCoordinator.didSendSuccessfully = { [weak self, weak navigationController] in
            self?.sendTokenCoordinator = nil
            navigationController?.dismiss(animated: true, completion: { [weak self] in
                self?.inAppReviewService.trackSuccessfulSend()
                guard let successReturn else { return }
                self?.openURL(successReturn, title: nil)
            })
            self?.removeChild($0)
        }

        sendTokenCoordinator.didRequestOpenBuySell = { [weak self] isInternalPurchasing in
            self?.openBuy(wallet: wallet, isInternalPurchasing: isInternalPurchasing)
        }
        sendTokenCoordinator.didRequestRefill = { [weak self] token in
            guard let self else { return }
            router.dismiss(animated: true) { [weak self] in
                self?.openReceive(tokens: [token], wallet: wallet)
            }
        }
        sendTokenCoordinator.didRequestOpenBattery = { [weak self] in
            self?.openBattery(wallet: wallet)
        }

        self.sendTokenCoordinator = sendTokenCoordinator

        addChild(sendTokenCoordinator)

        sendTokenCoordinator.start()

        router.presentOverTopPresented(
            navigationController,
            animated: true,
            completion: nil
        ) { [weak self, weak sendTokenCoordinator] in
            self?.sendTokenCoordinator = nil
            guard let sendTokenCoordinator else { return }
            self?.removeChild(sendTokenCoordinator)
        }
    }

    func openSendPushedOnto(
        wallet: Wallet,
        sendInput: SendInput,
        sendSource: SendAnalyticsSource,
        comment: String?,
        pushRouter: NavigationControllerRouter
    ) {
        let sendTokenCoordinator = SendModule(
            dependencies: SendModule.Dependencies(
                coreAssembly: coreAssembly,
                keeperCoreMainAssembly: keeperCoreMainAssembly
            )
        ).createSendTokenCoordinator(
            router: pushRouter,
            wallet: wallet,
            sendInput: sendInput,
            sendSource: sendSource,
            recipient: nil,
            comment: comment
        )

        sendTokenCoordinator.didFinish = { [weak self, weak pushRouter] in
            self?.sendTokenCoordinator = nil
            pushRouter?.rootViewController.dismiss(animated: true)
            self?.removeChild($0)
        }

        sendTokenCoordinator.didSendSuccessfully = { [weak self, weak pushRouter] in
            self?.sendTokenCoordinator = nil
            pushRouter?.rootViewController.popViewController(animated: true)
            self?.removeChild($0)
            self?.inAppReviewService.trackSuccessfulSend()
            self?.openHistory()
        }

        sendTokenCoordinator.didRequestOpenBuySell = { [weak self] isInternalPurchasing in
            self?.openBuy(wallet: wallet, isInternalPurchasing: isInternalPurchasing)
        }
        sendTokenCoordinator.didRequestRefill = { [weak self] token in
            guard let self else { return }
            router.dismiss(animated: true) { [weak self] in
                self?.openReceive(tokens: [token], wallet: wallet)
            }
        }
        sendTokenCoordinator.didRequestOpenBattery = { [weak self] in
            self?.openBattery(wallet: wallet)
        }

        self.sendTokenCoordinator = sendTokenCoordinator

        addChild(sendTokenCoordinator)

        sendTokenCoordinator.start(pushAnimated: true)
    }

    func openSwap(wallet: Wallet, token: Token) {
        switch token {
        case let .ton(tonToken):
            let fromToken: String?
            let toToken: String?
            switch tonToken {
            case .ton:
                fromToken = TonInfo.symbol
                toToken = nil
            case let .jetton(jetton):
                fromToken = jetton.jettonInfo.address.toRaw()
                if jetton.jettonInfo.address == JettonMasterAddress.USDe {
                    toToken = JettonMasterAddress.tonUSDT.toRaw()
                } else if jetton.jettonInfo.address == JettonMasterAddress.tsUSDe {
                    toToken = JettonMasterAddress.USDe.toRaw()
                } else {
                    toToken = TonInfo.symbol
                }
            }

            let configuration = keeperCoreMainAssembly.configurationAssembly.configuration
            if configuration.flag(\.nativeSwapDisabled, network: wallet.network) {
                openWebSwap(
                    wallet: wallet,
                    fromToken: fromToken,
                    toToken: toToken
                )
            } else if configuration.featureEnabled(.multichainEnabled) {
                openMultichainSwap(
                    wallet: wallet,
                    nativeSwapContext: NativeSwapContext(
                        fromTokenAddress: fromToken,
                        toTokenAddress: toToken
                    )
                )
            } else {
                openNativeSwap(
                    wallet: wallet,
                    nativeSwapContext: NativeSwapContext(
                        fromTokenAddress: fromToken,
                        toTokenAddress: toToken
                    )
                )
            }
        case .tron:
            openTRC20Swap()
        }
    }

    func openMultichainSwap(
        wallet: Wallet,
        nativeSwapContext: NativeSwapContext = NativeSwapContext(),
        presentingViewController: UIViewController? = nil
    ) {
        let navigationController = TKNavigationController()
        navigationController.configureDefaultAppearance()
        navigationController.setNavigationBarHidden(true, animated: false)

        let coordinator = MultichainSwapCoordinator(
            wallet: wallet,
            nativeSwapContext: nativeSwapContext,
            router: NavigationControllerRouter(rootViewController: navigationController),
            coreAssembly: coreAssembly,
            keeperCoreMainAssembly: keeperCoreMainAssembly
        )

        multichainSwapCoordinator = coordinator

        coordinator.didFinish = { [weak self, weak coordinator, weak navigationController] _ in
            guard let self, let coordinator else { return }

            navigationController?.dismiss(animated: true)
            removeChild(coordinator)
        }

        coordinator.didRequestOpenBuySell = { [weak self] isInternalPurchasing in
            guard let self else { return }

            openBuy(wallet: wallet, isInternalPurchasing: isInternalPurchasing)
        }

        addChild(coordinator)
        coordinator.start()

        if let presentingViewController {
            presentingViewController
                .topPresentedViewController()
                .present(navigationController, animated: true)
        } else {
            router.dismiss(animated: true) { [weak self] in
                self?.router.present(navigationController, onDismiss: { [weak self, weak coordinator] in
                    self?.removeChild(coordinator)
                })
            }
        }
    }

    func openNativeSwap(
        wallet: Wallet,
        nativeSwapContext: NativeSwapContext = NativeSwapContext(),
        presentingViewController: UIViewController? = nil
    ) {
        let navigationController = TKNavigationController()
        navigationController.configureDefaultAppearance()
        navigationController.setNavigationBarHidden(true, animated: false)

        let coordinator = NativeSwapModule(
            dependencies: NativeSwapModule.Dependencies(
                coreAssembly: coreAssembly,
                keeperCoreMainAssembly: keeperCoreMainAssembly
            )
        ).swapCoordinator(
            wallet: wallet,
            nativeSwapContext: nativeSwapContext,
            router: NavigationControllerRouter(rootViewController: navigationController)
        )

        nativeSwapCoordinator = coordinator

        coordinator.didFinish = { [weak self, weak coordinator, weak navigationController] _ in
            guard let self, let coordinator else { return }

            navigationController?.dismiss(animated: true)
            removeChild(coordinator)
        }

        coordinator.didRequestOpenBuySell = { [weak self] isInternalPurchasing in
            guard let self else { return }

            openBuy(wallet: wallet, isInternalPurchasing: isInternalPurchasing)
        }

        addChild(coordinator)
        coordinator.start()

        if let presentingViewController {
            presentingViewController
                .topPresentedViewController()
                .present(navigationController, animated: true)
        } else {
            router.dismiss(animated: true) { [weak self] in
                self?.router.present(navigationController, onDismiss: { [weak self, weak coordinator] in
                    self?.removeChild(coordinator)
                })
            }
        }
    }

    func openWebSwap(
        wallet: Wallet,
        fromToken: String? = nil,
        toToken: String? = nil,
        presentingViewController: UIViewController? = nil
    ) {
        let navigationController = TKNavigationController()
        navigationController.configureDefaultAppearance()
        navigationController.setNavigationBarHidden(true, animated: false)

        let coordinator = WebSwapModule(
            dependencies: WebSwapModule.Dependencies(
                coreAssembly: coreAssembly,
                keeperCoreMainAssembly: keeperCoreMainAssembly
            )
        ).swapCoordinator(
            wallet: wallet,
            fromToken: fromToken,
            toToken: toToken,
            router: NavigationControllerRouter(rootViewController: navigationController)
        )

        coordinator.didClose = { [weak self, weak coordinator, weak navigationController] in
            navigationController?.dismiss(animated: true)
            guard let coordinator else { return }

            self?.removeChild(coordinator)
        }

        self.webSwapCoordinator = coordinator

        addChild(coordinator)
        coordinator.start()

        if let presentingViewController {
            presentingViewController
                .topPresentedViewController()
                .present(navigationController, animated: true)
        } else {
            router.dismiss(animated: true) { [weak self] in
                self?.router.present(navigationController, onDismiss: { [weak self, weak coordinator] in
                    self?.removeChild(coordinator)
                })
            }
        }
    }

    private var trc20SwapOpenTask: Task<Void, Swift.Error>?
    func openTRC20Swap() {
        trc20SwapOpenTask?.cancel()
        trc20SwapOpenTask = Task { [weak self] in
            guard let self else { return }

            let service = keeperCoreMainAssembly.buySellAssembly.buySellMethodsService()
            guard let methods = try? await service.loadFiatMethods(countryCode: nil) else { return }

            if Task.isCancelled { return }

            guard let url = methods.buy
                .flatMap(\.items)
                .first(where: { $0.id == "letsexchange_buy_swap" })
                .flatMap({ URL(string: $0.actionButton.url) })
            else { return }

            openURL(url, title: nil)
        }
    }

    func handleTonkeeperDeeplink(_ deeplink: KeeperCore.Deeplink, fromStories: Bool, sendSource: SendAnalyticsSource) -> Bool {
        switch deeplink {
        case let .transfer(data):
            switch data {
            case let .sendTransfer(sendTransferData):
                openSendDeeplink(
                    recipient: sendTransferData.recipient,
                    amount: sendTransferData.amount,
                    comment: sendTransferData.comment,
                    jettonAddress: sendTransferData.jettonAddress,
                    expirationTimestamp: sendTransferData.expirationTimestamp,
                    successReturn: sendTransferData.successReturn,
                    sendSource: sendSource
                )
                return true
            case let .signRawTransfer(signRawTransferData):
                openSignRawSendDeeplink(
                    recipient: signRawTransferData.recipient,
                    jettonMaster: signRawTransferData.jettonAddress,
                    amount: signRawTransferData.amount,
                    bin: signRawTransferData.bin,
                    stateInit: signRawTransferData.stateInit,
                    expirationTimestamp: signRawTransferData.expirationTimestamp
                )
                return true
            }
        case .buyTon:
            openBuyDeeplink()
            return true
        case .staking:
            openStakingDeeplink()
            return true
        case let .pool(poolAddress):
            openPoolDetailsDeeplink(poolAddress: poolAddress)
            return true
        case let .exchange(provider):
            openExchangeDeeplink(provider: provider)
            return true
        case let .swap(data):
            openSwapDeeplink(fromToken: data.fromToken, toToken: data.toToken)
            return true
        case let .action(eventId):
            openActionDeeplink(eventId: eventId)
            return true
        case let .publish(sign):
            if let walletTransferSignCoordinator {
                walletTransferSignCoordinator.externalSignHandler?(sign)
                walletTransferSignCoordinator.externalSignHandler = nil
                return true
            }
            if let sendTokenCoordinator = sendTokenCoordinator {
                return sendTokenCoordinator.handleTonkeeperPublishDeeplink(sign: sign)
            }
            if let collectiblesCoordinator = collectiblesCoordinator,
               collectiblesCoordinator.handleTonkeeperDeeplink(deeplink: deeplink)
            {
                return true
            }
            if let webSwapCoordinator = webSwapCoordinator,
               webSwapCoordinator.handleTonkeeperPublishDeeplink(sign: sign)
            {
                return true
            }
            if let nativeSwapCoordinator = nativeSwapCoordinator,
               nativeSwapCoordinator.handleTonkeeperPublishDeeplink(sign: sign)
            {
                return true
            }
            if let multichainSwapCoordinator = multichainSwapCoordinator,
               multichainSwapCoordinator.handleTonkeeperPublishDeeplink(sign: sign)
            {
                return true
            }
            if let batteryRefillCoordinator,
               batteryRefillCoordinator.handleTonkeeperPublishDeeplink(sign: sign)
            {
                return true
            }
            if let stakingCoordinator,
               stakingCoordinator.handleTonkeeperPublishDeeplink(sign: sign)
            {
                return true
            }
            if let stakingStakeCoordinator,
               stakingStakeCoordinator.handleTonkeeperPublishDeeplink(sign: sign)
            {
                return true
            }
            if let stakingUnstakeCoordinator,
               stakingUnstakeCoordinator.handleTonkeeperPublishDeeplink(sign: sign)
            {
                return true
            }
            if let stakingConfirmationCoordinator,
               stakingConfirmationCoordinator.handleTonkeeperPublishDeeplink(sign: sign)
            {
                return true
            }
            return false
        case let .externalSign(data):
            return handleSignerDeeplink(data)
        case let .tonconnect(parameters):
            return handleTonConnectDeeplink(parameters)
        case let .dapp(dappURL):
            return handleDappDeeplink(url: dappURL)
        case .browser:
            openBrowserTabExplore()
            coreAssembly.analyticsProvider.log(
                eventKey: .openBrowser,
                args: ["from": fromStories ? "story" : "deep-link"]
            )
            return true
        case let .trading(gridID):
            return openTradingDeeplink(
                gridID: gridID,
                source: tradeFlowAnalyticsSource(for: sendSource)
            )
        case let .tradeAsset(assetID):
            return openTradeAssetDeeplink(
                assetID: assetID,
                source: assetViewAnalyticsSource(for: sendSource)
            )
        case let .battery(battery):
            handleBatteryDeeplink(battery)
            return true
        case let .story(storyId):
            handleStoryDeeplink(storyId: storyId)
            return true
        case .receive:
            openReceiveDeeplink()
            return true
        case .backup:
            openBackupDeeplink()
            return true
        case .main:
            openMainDeeplink()
            return true
        case let .deposit(parameters):
            openRampDeeplink(flow: .deposit, parameters: parameters, entrySource: depositAnalyticsSource(for: sendSource))
            return true
        case let .withdraw(parameters):
            openRampDeeplink(flow: .withdraw, parameters: parameters, entrySource: depositAnalyticsSource(for: sendSource))
            return true
        }
    }

    // MARK: -  TODO: complete on next iteration: flow: .deeplink

    func handleTonConnectDeeplink(_ payload: TonConnectPayload) -> Bool {
        switch payload {
        case .empty:
            return false
        case let .withParameters(parameters, url):
            if keeperCoreMainAssembly.configurationAssembly.configuration.featureEnabled(.walletKitEnabled) {
                return handleTonConnectDeeplink(url: url)
            } else {
                return handleTonConnectDeeplink(parameters: parameters)
            }
        }
    }

    private func handleTonConnectDeeplink(url: URL) -> Bool {
        ToastPresenter.hideAll()
        ToastPresenter.showToast(configuration: .loading)

        Task {
            do {
                try await keeperCoreMainAssembly.tonWalletKitAssembly.tonWalletKit.connect(url: url.absoluteString)

                await MainActor.run {
                    ToastPresenter.hideToast()
                }
            } catch {
                await MainActor.run {
                    ToastPresenter.hideToast()
                    ToastPresenter.showToast(
                        configuration: ToastPresenter.Configuration(
                            title: error.localizedDescription
                        )
                    )
                }
            }
        }
        return true
    }

    private func handleTonConnectDeeplink(parameters: TonConnectParameters) -> Bool {
        let tonConnectService = keeperCoreMainAssembly.tonConnectAssembly.tonConnectService()

        ToastPresenter.hideAll()
        ToastPresenter.showToast(configuration: .loading)
        guard let windowScene = router.rootViewController.windowScene else {
            return false
        }
        let window = TKWindow(windowScene: windowScene)
        window.windowLevel = .tonConnectConnect
        let router = WindowRouter(window: window)
        Task {
            switch await tonConnectService.loadAppManifest(parameters: parameters) {
            case let .success(manifest):
                await MainActor.run {
                    ToastPresenter.hideToast()
                    let coordinator = TonConnectModule(
                        dependencies: TonConnectModule.Dependencies(
                            coreAssembly: coreAssembly,
                            keeperCoreMainAssembly: keeperCoreMainAssembly
                        )
                    ).createConnectCoordinator(
                        router: router,
                        flow: .common,
                        connector: DefaultTonConnectConnectCoordinatorConnector(
                            tonConnectAppsStore: keeperCoreMainAssembly.tonConnectAssembly.tonConnectAppsStore
                        ),
                        parameters: parameters,
                        manifest: manifest,
                        showWalletPicker: true,
                        isSilentConnect: false
                    )

                    coordinator.didCancel = { [weak self, weak coordinator] in
                        guard let coordinator else { return }
                        self?.removeChild(coordinator)
                    }

                    coordinator.didConnect = { [weak self, weak coordinator] in
                        guard let coordinator else { return }
                        self?.removeChild(coordinator)
                    }

                    coordinator.didRequestOpeningBrowser = { [weak self] manifest in
                        self?.openDapp(title: manifest.name, url: manifest.url)
                    }

                    addChild(coordinator)
                    coordinator.start()
                }
            case let .failure(error):
                ToastPresenter.hideToast()
                ToastPresenter.showToast(
                    configuration: ToastPresenter.Configuration(
                        title: error.description
                    )
                )
            }
        }
        return true
    }

    func handleSignerDeeplink(_ deeplink: ExternalSignDeeplink) -> Bool {
        let navigationController = TKNavigationController()
        navigationController.configureTransparentAppearance()

        switch deeplink {
        case let .link(publicKey, name):
            let coordinator = AddWalletModule(
                dependencies: AddWalletModule.Dependencies(
                    walletsUpdateAssembly: keeperCoreMainAssembly.walletUpdateAssembly,
                    storesAssembly: keeperCoreMainAssembly.storesAssembly,
                    coreAssembly: coreAssembly,
                    scannerAssembly: keeperCoreMainAssembly.scannerAssembly(),
                    configurationAssembly: keeperCoreMainAssembly.configurationAssembly
                )
            ).createPairSignerDeeplinkCoordinator(
                publicKey: publicKey,
                name: name,
                router: NavigationControllerRouter(
                    rootViewController: navigationController
                )
            )

            coordinator.didPrepareToPresent = { [weak self, weak navigationController] in
                guard let navigationController else { return }
                if self?.router.rootViewController.presentedViewController != nil {
                    self?.router.dismiss(animated: true, completion: {
                        self?.router.present(navigationController)
                    })
                } else {
                    self?.router.present(navigationController)
                }
            }

            coordinator.didPaired = { [weak self, weak coordinator, weak navigationController] in
                navigationController?.dismiss(animated: true)
                self?.removeChild(coordinator)
            }

            coordinator.didCancel = { [weak self, weak coordinator, weak navigationController] in
                navigationController?.dismiss(animated: true)
                self?.removeChild(coordinator)
            }

            addChild(coordinator)
            coordinator.start()
        }
        return true
    }

    func openWalletPicker() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        let module = WalletsListAssembly.module(
            model: WalletsPickerListModel(
                walletsStore: keeperCoreMainAssembly.storesAssembly.walletsStore
            ),
            balanceLoader: keeperCoreMainAssembly.loadersAssembly.balanceLoader,
            totalBalancesStore: keeperCoreMainAssembly.storesAssembly.totalBalanceStore,
            appSettingsStore: keeperCoreMainAssembly.storesAssembly.appSettingsStore,
            amountFormatter: keeperCoreMainAssembly.formattersAssembly.amountFormatter
        )

        let bottomSheetViewController = TKBottomSheetViewController(contentViewController: module.view)

        module.output.addButtonEvent = { [weak self, unowned bottomSheetViewController] in
            bottomSheetViewController.dismiss {
                guard let self else { return }
                self.openAddWallet(router: ViewControllerRouter(rootViewController: self.router.rootViewController))
            }
        }

        module.output.didTapEditWallet = { [weak self, unowned bottomSheetViewController] wallet in
            self?.openEditWallet(wallet: wallet, fromViewController: bottomSheetViewController)
        }

        module.output.didSelectWallet = { [weak bottomSheetViewController] in
            bottomSheetViewController?.dismiss()
        }

        bottomSheetViewController.present(fromViewController: router.rootViewController)
    }

    func openAddWallet(router: ViewControllerRouter) {
        let module = AddWalletModule(
            dependencies: AddWalletModule.Dependencies(
                walletsUpdateAssembly: keeperCoreMainAssembly.walletUpdateAssembly,
                storesAssembly: keeperCoreMainAssembly.storesAssembly,
                coreAssembly: coreAssembly,
                scannerAssembly: keeperCoreMainAssembly.scannerAssembly(),
                configurationAssembly: keeperCoreMainAssembly.configurationAssembly
            )
        )

        let coordinator = module.createAddWalletCoordinator(
            options: [.createRegular, .importRegular, .signer, .keystone, .ledger, .importWatchOnly, .importTestnet, .importTetra],
            router: router
        )
        coordinator.didAddWallets = { [weak self, weak coordinator] in
            self?.addWalletCoordinator = nil
            guard let coordinator else { return }
            self?.removeChild(coordinator)
        }
        coordinator.didCancel = { [weak self, weak coordinator] in
            self?.addWalletCoordinator = nil
            guard let coordinator else { return }
            self?.removeChild(coordinator)
        }

        addWalletCoordinator = coordinator

        addChild(coordinator)
        coordinator.start()
    }

    func openEditWallet(wallet: Wallet, fromViewController: UIViewController) {
        let addWalletModuleModule = AddWalletModule(
            dependencies: AddWalletModule.Dependencies(
                walletsUpdateAssembly: keeperCoreMainAssembly.walletUpdateAssembly,
                storesAssembly: keeperCoreMainAssembly.storesAssembly,
                coreAssembly: coreAssembly,
                scannerAssembly: keeperCoreMainAssembly.scannerAssembly(),
                configurationAssembly: keeperCoreMainAssembly.configurationAssembly
            )
        )

        let module = addWalletModuleModule.createCustomizeWalletModule(
            name: wallet.label,
            tintColor: wallet.tintColor,
            icon: wallet.metaData.icon,
            configurator: EditWalletCustomizeWalletViewModelConfigurator()
        )

        module.output.didCustomizeWallet = { [weak self] model in
            guard let self else { return }
            let walletsStore = self.keeperCoreMainAssembly.storesAssembly.walletsStore
            Task {
                await walletsStore.updateWalletMetaData(
                    wallet,
                    metaData: WalletMetaData(customizeWalletModel: model)
                )
            }
        }

        let navigationController = TKNavigationController(rootViewController: module.view)

        module.view.setupRightCloseButton { [weak navigationController] in
            navigationController?.dismiss(animated: true)
        }

        fromViewController.present(navigationController, animated: true)
    }

    func openSupport() {
        let directSupportURL = keeperCoreMainAssembly.configurationAssembly.configuration.directSupportUrl
        let supportEmailURL = keeperCoreMainAssembly.configurationAssembly.configuration.supportLink
        let urlOpener = coreAssembly.urlOpener()

        let module = SupportPopupAssembly.module(
            directSupportURL: directSupportURL,
            supportEmailURL: supportEmailURL
        )
        let bottomSheetViewController = TKBottomSheetViewController(contentViewController: module.view)
        bottomSheetViewController.present(fromViewController: router.rootViewController.topPresentedViewController())

        module.output.didOpenURL = { [weak bottomSheetViewController] in
            bottomSheetViewController?.dismiss()
            urlOpener.open(url: $0)
        }
    }

    func openSettings(wallet: Wallet) {
        guard let navigationController = router.rootViewController.navigationController else { return }
        let module = SettingsModule(
            dependencies: SettingsModule.Dependencies(
                inAppReviewService: inAppReviewService,
                keeperCoreMainAssembly: keeperCoreMainAssembly,
                coreAssembly: coreAssembly
            )
        )

        let router = NavigationControllerRouter(rootViewController: navigationController)

        let coordinator = module.createSettingsCoordinator(
            router: router,
            wallet: wallet
        )

        coordinator.didTapBattery = { [weak self] wallet in
            self?.openBattery(
                wallet: wallet
            )
        }

        coordinator.didTapSupport = { [weak self] in
            self?.openSupport()
        }

        coordinator.didFinish = { [weak self] in
            self?.removeChild($0)
        }

        addChild(coordinator)
        coordinator.start()
    }

    func openTonDetails(
        wallet: Wallet,
        analyticsSource: AssetViewAnalyticsSource = .walletScreen,
        navigationControllerOrNil: UINavigationController? = nil
    ) {
        let navigationController = navigationControllerOrNil ?? router.rootViewController.navigationController
        guard let navigationController else {
            return
        }
        let configuration = keeperCoreMainAssembly.configurationAssembly.configuration
        if configuration.featureEnabled(.tradingUiEnabled),
           wallet.network.isMainnet,
           let tradeCoordinator
        {
            tradeCoordinator.openAssetDetails(
                preview: AssetIdResolver
                    .tonPreviewContext(
                        wallet: wallet
                    ),
                on: navigationController,
                source: analyticsSource
            )
            return
        }
        let historyListModule = HistoryModule(
            dependencies: HistoryModule.Dependencies(
                coreAssembly: coreAssembly,
                keeperCoreMainAssembly: keeperCoreMainAssembly
            )
        ).createTonHistoryListModule(wallet: wallet)

        historyListModule.output.didSelectEvent = { [weak self] event in
            switch event {
            case let .tonEvent(event):
                self?.openHistoryEventDetails(wallet: wallet, event: event, network: wallet.network, fromViewController: nil)
            case let .tronEvent(event):
                self?.openTronEventDetails(wallet: wallet, event: event, network: wallet.network, fromViewController: nil)
            }
        }

        let module = TokenDetailsAssembly.module(
            wallet: wallet,
            balanceLoader: keeperCoreMainAssembly.loadersAssembly.balanceLoader,
            balanceStore: keeperCoreMainAssembly.storesAssembly.processedBalanceStore,
            appSettingsStore: keeperCoreMainAssembly.storesAssembly.appSettingsStore,
            configurator: makeTokenDetailsConfigurator(
                wallet: wallet,
                token: .ton(.ton)
            ),
            tokenDetailsListContentViewController: historyListModule.view,
            chartViewControllerProvider: { [keeperCoreMainAssembly, coreAssembly] in
                ChartAssembly.module(
                    token: .ton(.ton),
                    coreAssembly: coreAssembly,
                    keeperCoreMainAssembly: keeperCoreMainAssembly
                ).view
            },
            shouldReserveChartSpace: true
        )

        module.output.didTapReceive = { [weak self] token in
            self?.openReceive(tokens: [token], wallet: wallet)
        }

        module.output.didTapSend = { [weak self] token in
            self?.openSend(
                wallet: wallet,
                sendInput: .direct(item: token.sendV3Item),
                sendSource: .jettonScreen,
                comment: nil
            )
        }

        module.output.didTapBuyOrSell = { [weak self] in
            self?.openBuy(wallet: wallet)
        }

        module.output.didTapSwap = { [weak self] token in
            self?.openSwap(wallet: wallet, token: token)
        }

        module.output.didOpenURL = { [weak self] url in
            self?.openURL(url, title: nil)
        }

        navigationController.pushViewController(module.view, animated: true)
    }

    func openJettonDetails(
        jettonItem: JettonItem,
        wallet: Wallet,
        hasPrice: Bool,
        analyticsSource: AssetViewAnalyticsSource = .walletScreen,
        navigationControllerOrNil: UINavigationController? = nil
    ) {
        let navigationController = navigationControllerOrNil ?? router.rootViewController.navigationController
        guard let navigationController else {
            return
        }
        let configuration = keeperCoreMainAssembly.configurationAssembly.configuration
        if configuration.featureEnabled(.tradingUiEnabled),
           wallet.network.isMainnet,
           let tradeCoordinator
        {
            tradeCoordinator.openAssetDetails(
                preview: AssetIdResolver
                    .jettonPreviewContext(
                        wallet: wallet,
                        jettonItem: jettonItem
                    ),
                on: navigationController,
                source: analyticsSource
            )
            return
        }

        let historyListModule = HistoryModule(
            dependencies: HistoryModule.Dependencies(
                coreAssembly: coreAssembly,
                keeperCoreMainAssembly: keeperCoreMainAssembly
            )
        ).createJettonHistoryListModule(jettonMasterAddress: jettonItem.jettonInfo.address, wallet: wallet)

        historyListModule.output.didSelectEvent = { [weak self] event in
            switch event {
            case let .tonEvent(event):
                self?.openHistoryEventDetails(wallet: wallet, event: event, network: wallet.network, fromViewController: nil)
            case let .tronEvent(event):
                self?.openTronEventDetails(wallet: wallet, event: event, network: wallet.network, fromViewController: nil)
            }
        }

        let module = TokenDetailsAssembly.module(
            wallet: wallet,
            balanceLoader: keeperCoreMainAssembly.loadersAssembly.balanceLoader,
            balanceStore: keeperCoreMainAssembly.storesAssembly.processedBalanceStore,
            appSettingsStore: keeperCoreMainAssembly.storesAssembly.appSettingsStore,
            configurator: makeTokenDetailsConfigurator(
                wallet: wallet,
                token: .ton(.jetton(jettonItem))
            ),
            tokenDetailsListContentViewController: historyListModule.view,
            chartViewControllerProvider: { [keeperCoreMainAssembly, coreAssembly] in
                guard hasPrice else { return nil }
                return ChartAssembly.module(
                    token: .ton(.jetton(jettonItem)),
                    coreAssembly: coreAssembly,
                    keeperCoreMainAssembly: keeperCoreMainAssembly
                ).view
            },
            shouldReserveChartSpace: hasPrice
        )

        module.output.didTapReceive = { [weak self] token in
            self?.openReceive(tokens: [token], wallet: wallet)
        }

        module.output.didTapSend = { [weak self] token in
            self?.openSend(
                wallet: wallet,
                sendInput: .direct(item: token.sendV3Item),
                sendSource: .jettonScreen,
                comment: nil
            )
        }

        module.output.didTapSwap = { [weak self] token in
            self?.openSwap(wallet: wallet, token: token)
        }

        module.output.didOpenURL = { [weak self] url in
            self?.openURL(url, title: nil)
        }

        navigationController.pushViewController(module.view, animated: true)
    }

    func openTronUSDTDetails(
        wallet: Wallet,
        analyticsSource: AssetViewAnalyticsSource = .walletScreen,
        navigationControllerOrNil: UINavigationController? = nil
    ) {
        let navigationController = navigationControllerOrNil ?? router.rootViewController.navigationController
        guard let navigationController else {
            return
        }
        Task {
            await keeperCoreMainAssembly.servicesAssembly.tronUSDTFeesService.refresh(wallet: wallet)
        }

        let historyListModule = HistoryModule(
            dependencies: HistoryModule.Dependencies(
                coreAssembly: coreAssembly,
                keeperCoreMainAssembly: keeperCoreMainAssembly
            )
        ).createTronUSDTHistoryListModule(wallet: wallet)

        historyListModule.output.didSelectEvent = { [weak self] event in
            switch event {
            case let .tonEvent(event):
                self?.openHistoryEventDetails(wallet: wallet, event: event, network: wallet.network, fromViewController: nil)
            case let .tronEvent(event):
                self?.openTronEventDetails(wallet: wallet, event: event, network: wallet.network, fromViewController: nil)
            }
        }

        let configuration = makeTronDetailsConfigurator(wallet: wallet)

        let module = TokenDetailsAssembly.module(
            wallet: wallet,
            balanceLoader: keeperCoreMainAssembly.loadersAssembly.balanceLoader,
            balanceStore: keeperCoreMainAssembly.storesAssembly.processedBalanceStore,
            appSettingsStore: keeperCoreMainAssembly.storesAssembly.appSettingsStore,
            configurator: configuration,
            tokenDetailsListContentViewController: historyListModule.view,
            chartViewControllerProvider: { [keeperCoreMainAssembly, coreAssembly] in
                ChartAssembly.module(
                    token: .tron(.usdt),
                    coreAssembly: coreAssembly,
                    keeperCoreMainAssembly: keeperCoreMainAssembly
                ).view
            },
            shouldReserveChartSpace: true
        )

        module.output.didTapReceive = { [weak self] token in
            self?.openReceive(tokens: [token], wallet: wallet)
        }

        module.output.didTapSend = { [weak self, weak configuration] token in
            guard let self, let configuration else {
                return
            }
            let tronUSDTFeesService = keeperCoreMainAssembly.servicesAssembly.tronUSDTFeesService
            let feesSnapshot = keeperCoreMainAssembly.storesAssembly
                .processedBalanceStore
                .getState()[wallet]
                .flatMap { state in
                    tronUSDTFeesService.snapshot(wallet: wallet, balance: state.balance)
                }
            if let feesSnapshot, !feesSnapshot.hasEnoughForAtLeastOneTransfer {
                if feesSnapshot.isTRXOnlyRegion {
                    return openInsufficientFundsPopup(
                        configuration: configuration.insufficientTrxSheetConfiguration(
                            for: feesSnapshot,
                            onGetTrx: { [weak self] in
                                guard let self else {
                                    return
                                }
                                router.dismiss { [weak self] in
                                    self?.openReceive(tokens: [.tron(.trx)], wallet: wallet)
                                }
                            }
                        )
                    )
                } else {
                    return openUsdtFees(wallet: wallet, snapshot: feesSnapshot, reason: .insufficient)
                }
            }

            openSend(
                wallet: wallet,
                sendInput: .direct(item: token.sendV3Item),
                sendSource: .jettonScreen,
                comment: nil
            )
        }

        module.output.didTapBuyOrSell = { [weak self] in
            self?.openBuy(wallet: wallet)
        }

        module.output.didTapSwap = { [weak self] token in
            self?.openSwap(wallet: wallet, token: token)
        }

        module.output.didOpenURL = { [weak self] url in
            self?.openURL(url, title: nil)
        }

        navigationController.pushViewController(module.view, animated: true)
    }

    func openUsdtFees(wallet: Wallet, snapshot: TronUsdtFeesSnapshot, reason: TopUpReason) {
        guard let navigationController = router.rootViewController.navigationController else { return }

        let coordinator = TopUpCoordinator(
            wallet: wallet,
            reason: reason,
            snapshot: snapshot,
            keeperCoreMainAssembly: keeperCoreMainAssembly,
            coreAssembly: coreAssembly,
            router: NavigationControllerRouter(rootViewController: navigationController)
        )
        coordinator.openBattery = { [weak self] in
            self?.openBattery(wallet: wallet, keepCurrentModal: true)
        }
        self.topUpCoordinator = coordinator

        addChild(coordinator)
        coordinator.start()
    }

    func openEthenaDetails(wallet: Wallet) {
        guard let navigationController = router.rootViewController.navigationController else { return }

        let historyListModule = HistoryModule(
            dependencies: HistoryModule.Dependencies(
                coreAssembly: coreAssembly,
                keeperCoreMainAssembly: keeperCoreMainAssembly
            )
        ).createJettonHistoryListModule(jettonMasterAddress: JettonMasterAddress.USDe, wallet: wallet)

        historyListModule.output.didSelectEvent = { [weak self] event in
            switch event {
            case let .tonEvent(event):
                self?.openHistoryEventDetails(wallet: wallet, event: event, network: wallet.network, fromViewController: nil)
            case let .tronEvent(event):
                self?.openTronEventDetails(wallet: wallet, event: event, network: wallet.network, fromViewController: nil)
            }
        }

        let configurator = EthenaDetailsConfigurator(
            wallet: wallet,
            mapper: TokenDetailsMapper(
                amountFormatter: keeperCoreMainAssembly.formattersAssembly.amountFormatter,
                rateConverter: RateConverter()
            ),
            configuration: keeperCoreMainAssembly.configurationAssembly.configuration,
            ethenaStakingLoader: keeperCoreMainAssembly.loadersAssembly.ethenaStakingLoader(wallet: wallet),
            balanceItemMapper: BalanceItemMapper(
                amountFormatter: keeperCoreMainAssembly.formattersAssembly.amountFormatter
            ),
            amountFormatter: keeperCoreMainAssembly.formattersAssembly.amountFormatter
        )

        configurator.didSelectJetton = { [weak self] jetton in
            self?.openJettonDetails(jettonItem: jetton, wallet: wallet, hasPrice: false)
        }

        configurator.didSelectStakingEthena = { [weak self] in
            self?.openEthenaStakingDetails(wallet: wallet)
        }

        configurator.didOpenURL = { [weak self] url in
            self?.openInAppURL(url: url)
        }

        configurator.didOpenDapp = { [weak self] url, title in
            self?.openDapp(title: title, url: url, isSilentConnect: true)
        }

        let module = TokenDetailsAssembly.module(
            wallet: wallet,
            balanceLoader: keeperCoreMainAssembly.loadersAssembly.balanceLoader,
            balanceStore: keeperCoreMainAssembly.storesAssembly.processedBalanceStore,
            appSettingsStore: keeperCoreMainAssembly.storesAssembly.appSettingsStore,
            configurator: configurator,
            tokenDetailsListContentViewController: historyListModule.view,
            chartViewControllerProvider: nil
        )

        module.output.didTapReceive = { [weak self] token in
            self?.openReceive(tokens: [token], wallet: wallet)
        }

        module.output.didTapSend = { [weak self] token in
            self?.openSend(
                wallet: wallet,
                sendInput: .direct(item: token.sendV3Item),
                sendSource: .jettonScreen,
                comment: nil
            )
        }

        module.output.didTapSwap = { [weak self] token in
            self?.openSwap(wallet: wallet, token: token)
        }

        module.output.didOpenURL = { [weak self] url in
            self?.openURL(url, title: nil)
        }

        navigationController.pushViewController(module.view, animated: true)
    }

    func openEthenaStakingDetails(wallet: Wallet) {
        guard let navigationController = router.rootViewController.navigationController else { return }

        let module = EthenaStakingDetailsAssembly.module(
            wallet: wallet,
            keeperCoreMainAssembly: keeperCoreMainAssembly,
            coreAssembly: coreAssembly
        )

        module.output.didOpenURL = { [weak self] in
            self?.coreAssembly.urlOpener().open(url: $0)
        }

        module.output.didOpenURLInApp = { [weak self] url in
            self?.openInAppURL(url: url)
        }

        module.output.didOpenDapp = { [weak self] url, title in
            self?.openDapp(title: title, url: url)
        }

        module.output.openJettonDetails = { [weak self] wallet, jettonItem in
            self?.openJettonDetails(jettonItem: jettonItem, wallet: wallet, hasPrice: true)
        }

        module.output.didTapStake = { [weak self] wallet, stakingPoolInfo in
            self?.openStake(wallet: wallet, stakingPoolInfo: stakingPoolInfo)
        }

        module.output.didTapUnstake = { [weak self] wallet, stakingPoolInfo in
            self?.openUnstake(wallet: wallet, stakingPoolInfo: stakingPoolInfo)
        }

        module.output.didTapCollect = { [weak self] in
            self?.openStakingCollect(wallet: $0, stakingPoolInfo: $1, accountStackingInfo: $2)
        }

        module.view.setupBackButton()

        navigationController.pushViewController(module.view, animated: true)
    }

    func openStakingItemDetails(
        wallet: Wallet,
        stakingPoolInfo: StackingPoolInfo
    ) {
        guard let navigationController = router.rootViewController.navigationController else { return }

        let module = StakingBalanceDetailsAssembly.module(
            wallet: wallet,
            stakingPoolInfo: stakingPoolInfo,
            keeperCoreMainAssembly: keeperCoreMainAssembly
        )

        module.output.didOpenURL = { [weak self] in
            self?.coreAssembly.urlOpener().open(url: $0)
        }

        module.output.didOpenURLInApp = { [weak self] url, title in
            self?.openURL(url, title: title)
        }

        module.output.openJettonDetails = { [weak self] wallet, jettonItem in
            self?.openJettonDetails(jettonItem: jettonItem, wallet: wallet, hasPrice: true)
        }

        module.output.didTapStake = { [weak self] wallet, stakingPoolInfo in
            self?.openStake(wallet: wallet, stakingPoolInfo: stakingPoolInfo)
        }

        module.output.didTapUnstake = { [weak self] wallet, stakingPoolInfo in
            self?.openUnstake(wallet: wallet, stakingPoolInfo: stakingPoolInfo)
        }

        module.output.didTapCollect = { [weak self] in
            self?.openStakingCollect(wallet: $0, stakingPoolInfo: $1, accountStackingInfo: $2)
        }

        module.view.setupBackButton()

        navigationController.pushViewController(module.view, animated: true)
    }

    func openStakingCollect(
        wallet: Wallet,
        stakingPoolInfo: StackingPoolInfo,
        accountStackingInfo: AccountStackingInfo
    ) {
        let navigationController = TKNavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)

        let coordinator = StakingConfirmationCoordinator(
            wallet: wallet,
            item: StakingConfirmationItem(
                operation: .withdraw(stakingPoolInfo),
                amount: BigUInt(accountStackingInfo.readyWithdraw)
            ),
            keeperCoreMainAssembly: keeperCoreMainAssembly,
            coreAssembly: coreAssembly,
            router: NavigationControllerRouter(rootViewController: navigationController)
        )

        coordinator.didFinish = { [weak self] in
            self?.removeChild($0)
        }

        coordinator.didClose = { [weak self, weak coordinator, weak navigationController] in
            navigationController?.dismiss(animated: true)
            self?.removeChild(coordinator)
        }

        self.stakingConfirmationCoordinator = coordinator

        addChild(coordinator)
        coordinator.start(deeplink: nil)

        router.present(navigationController)
    }

    func openURL(_ url: URL, title: String?) {
        router.present(bridgeViewController(for: url, title: title))
    }

    private func bridgeViewController(for url: URL, title: String?) -> TKBridgeWebViewController {
        TKBridgeWebViewController(
            initialURL: url,
            initialTitle: nil,
            jsInjection: nil,
            configuration: .default,
            deeplinkHandler: { [weak self] url in
                guard let self else { return }
                let deeplinkParser = DeeplinkParser()
                let deeplink = try deeplinkParser.parse(string: url)
                _ = self.handleDeeplink(deeplink: deeplink, fromStories: false)
            }
        )
    }

    func openInAppURL(url: URL) {
        let viewController = SFSafariViewController(url: url)
        router.present(viewController)
    }

    func openBuySellItemURL(_ url: URL, fromViewController: UIViewController) {
        let deeplinkHandler = TKWebViewControllerNavigationHandler { [weak self] deeplink in
            _ = self?.handleDeeplink(deeplink: deeplink, fromStories: false)
        }

        let webViewController = TKWebViewController(url: url, handler: deeplinkHandler)
        let navigationController = UINavigationController(rootViewController: webViewController)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.configureTransparentAppearance()
        fromViewController.present(navigationController, animated: true)
    }

    func openStake(wallet: Wallet, stakingPoolInfo: StackingPoolInfo) {
        let navigationController = TKNavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)

        let coordinator = StakingStakeCoordinator(
            wallet: wallet,
            stakingPoolInfo: stakingPoolInfo,
            keeperCoreMainAssembly: keeperCoreMainAssembly,
            coreAssembly: coreAssembly,
            router: NavigationControllerRouter(rootViewController: navigationController)
        )

        coordinator.didFinish = { [weak self] in
            self?.router.dismiss()
            self?.removeChild($0)
        }

        coordinator.didClose = { [weak self, weak coordinator] in
            self?.router.dismiss()
            self?.removeChild(coordinator)
        }

        self.stakingStakeCoordinator = coordinator

        addChild(coordinator)
        coordinator.start(deeplink: nil)

        self.router.dismiss(animated: true) { [weak self] in
            self?.router.present(navigationController, onDismiss: { [weak self, weak coordinator] in
                self?.removeChild(coordinator)
            })
        }
    }

    func openUnstake(wallet: Wallet, stakingPoolInfo: StackingPoolInfo) {
        let navigationController = TKNavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)

        let coordinator = StakingUnstakeCoordinator(
            wallet: wallet,
            stakingPoolInfo: stakingPoolInfo,
            keeperCoreMainAssembly: keeperCoreMainAssembly,
            coreAssembly: coreAssembly,
            router: NavigationControllerRouter(rootViewController: navigationController)
        )

        coordinator.didFinish = { [weak self] in
            self?.router.dismiss()
            self?.removeChild($0)
        }

        coordinator.didClose = { [weak self, weak coordinator] in
            self?.router.dismiss()
            self?.removeChild(coordinator)
        }

        self.stakingUnstakeCoordinator = coordinator

        addChild(coordinator)
        coordinator.start(deeplink: nil)

        self.router.present(navigationController, onDismiss: { [weak self, weak coordinator] in
            self?.removeChild(coordinator)
        })
    }

    func openRamp(
        flow: RampFlow,
        wallet: Wallet,
        initialDeeplink: RampDeeplinkParameters? = nil,
        entrySource: DepositAnalyticsSource
    ) {
        let navigationController = TKNavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)
        let rampRouter = NavigationControllerRouter(rootViewController: navigationController)

        let coordinator = RampCoordinator(
            flow: flow,
            router: rampRouter,
            wallet: wallet,
            keeperCoreMainAssembly: keeperCoreMainAssembly,
            coreAssembly: coreAssembly,
            initialDeeplink: initialDeeplink,
            entrySource: entrySource,
            depositPendingTracker: depositPendingTracker
        )

        coordinator.didTapReceive = { [weak self] wallet in
            guard let self else { return }
            openReceive(
                tokens: getRampTokens(wallet: wallet),
                wallet: wallet,
                onDidDisplayToken: { [weak self] token in
                    guard let self, flow == .deposit else { return }
                    self.coreAssembly.analyticsProvider.log(
                        entrySource.makeDepositViewReceiveTokens(token: token)
                    )
                }
            )
        }

        coordinator.didTapSend = { [weak self] wallet, token in
            self?.openSend(
                wallet: wallet,
                sendInput: .direct(item: .ton(.token(token, amount: 0))),
                sendSource: .walletScreen,
                comment: nil
            )
        }

        coordinator.didTapOpenSendFromWithdraw = { [weak self] wallet, sendInput in
            self?.openSendPushedOnto(
                wallet: wallet,
                sendInput: sendInput,
                sendSource: .walletScreen,
                comment: nil,
                pushRouter: rampRouter
            )
        }

        coordinator.didTapOpenMerchant = { [weak self, weak navigationController] url in
            guard let self, let navigationController else { return }
            self.openBuySellItemURL(url, fromViewController: navigationController)
        }

        coordinator.didClose = { [weak self, weak coordinator] in
            self?.router.dismiss()
            self?.removeChild(coordinator)
        }

        coordinator.didRequestTRC20Enable = { [weak self] wallet, enableCompletion in
            self?.openReceiveTRC20Popup(wallet: wallet, enableCompletion: enableCompletion)
        }

        addChild(coordinator)
        coordinator.start()

        router.dismiss(animated: true) { [weak self] in
            self?.router.present(navigationController, onDismiss: { [weak self, weak coordinator] in
                self?.removeChild(coordinator)
            })
        }
    }

    func getRampTokens(wallet: Wallet) -> [Token] {
        let balanceStore = keeperCoreMainAssembly.storesAssembly.balanceStore
        let tronBalanceIsZero = balanceStore.getState()[wallet]?.walletBalance.tronBalance?.amount.isZero ?? true
        let configuration = keeperCoreMainAssembly.configurationAssembly.configuration
        let tronDisabled = configuration.flag(\.tronDisabled, network: wallet.network) && tronBalanceIsZero

        var tokens: [Token] = [.ton(.ton)]
        if !tronDisabled || wallet.isTronTurnOn, wallet.isTronAvailable {
            tokens.append(.tron(.usdt))
        }

        return tokens
    }

    func openReceive(
        tokens: [Token],
        wallet: Wallet,
        completion: (() -> Void)? = nil,
        onDidDisplayToken: ((Token) -> Void)? = nil
    ) {
        let coordinator = ReceiveModule(
            dependencies: .init(
                coreAssembly: coreAssembly,
                keeperCoreMainAssembly: keeperCoreMainAssembly
            )
        )
        .createReceiveCoordinator(
            router: router,
            tokens: tokens,
            wallet: wallet,
            passcodeProvider: getPasscode,
            didDisplayToken: onDidDisplayToken
        )

        coordinator.didClose = { [weak self, weak coordinator] in
            self?.removeChild(coordinator)
        }

        addChild(coordinator)
        coordinator.start()
        completion?()
    }

    func openStake(wallet: Wallet) {
        let navigationController = TKNavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)

        let coordinator = StakingCoordinator(
            wallet: wallet,
            keeperCoreMainAssembly: keeperCoreMainAssembly,
            coreAssembly: coreAssembly,
            router: NavigationControllerRouter(rootViewController: navigationController)
        )

        coordinator.didFinish = { [weak self] in
            self?.router.dismiss()
            self?.removeChild($0)
        }

        coordinator.didClose = { [weak self, weak coordinator] in
            self?.router.dismiss()
            self?.removeChild(coordinator)
        }

        self.stakingCoordinator = coordinator

        addChild(coordinator)
        coordinator.start(deeplink: nil)

        self.router.dismiss(animated: true) { [weak self] in
            self?.router.present(navigationController, onDismiss: { [weak self, weak coordinator] in
                self?.removeChild(coordinator)
            })
        }
    }

    func openBuy(wallet: Wallet, isInternalPurchasing: Bool) {
        if isInternalPurchasing {
            openBuy(wallet: wallet)
        } else {
            openBrowserDefiFlow()
        }
    }

    func presentStory(story: KeeperCore.Story, shouldDismissCurrentOnAction: Bool = false) {
        let fromViewController = self.router.rootViewController

        mainCoordinatorStoriesController?.presentStory(
            story: .init(id: story.story_id, story: story),
            fromViewController: fromViewController,
            fromAnalyticsProperty: "updates",
            shouldDismissCurrentOnAction: shouldDismissCurrentOnAction
        )
    }

    func openAllUpdates() {
        let module = AllUpdatesAssembly.module(
            storiesStore: keeperCoreMainAssembly.storesAssembly.storiesStore
        )

        module.output.didSelectStory = { [weak self] story in
            self?.presentStory(story: story, shouldDismissCurrentOnAction: true)
        }

        let navigationController = TKNavigationController(rootViewController: module.view)
        navigationController.setNavigationBarHidden(true, animated: false)

        router.present(navigationController, onDismiss: nil)
    }

    func openBuy(wallet: Wallet) {
        let coordinator = BuyCoordinator(
            wallet: wallet,
            keeperCoreMainAssembly: keeperCoreMainAssembly,
            coreAssembly: coreAssembly,
            router: ViewControllerRouter(rootViewController: self.router.rootViewController)
        )

        coordinator.didOpenItem = { [weak self] url, fromViewController in
            self?.openBuySellItemURL(url, fromViewController: fromViewController)
        }

        coordinator.didClose = { [weak coordinator, weak self] in
            self?.removeChild(coordinator)
        }

        self.router.dismiss(animated: true) { [weak self] in
            self?.addChild(coordinator)
            coordinator.start()
        }
    }

    func openHistoryEventDetails(
        wallet: Wallet,
        event: AccountEventDetailsEvent,
        network: Network,
        fromViewController: UIViewController?
    ) {
        let module = HistoryEventDetailsAssembly.module(
            wallet: wallet,
            event: .ton(event),
            keeperCoreAssembly: keeperCoreMainAssembly,
            network: network
        )
        let bottomSheetViewController = TKBottomSheetViewController(contentViewController: module.view)

        module.output.didSelectEncryptedComment = { [weak self] wallet, payload, eventId in
            self?.decryptComment(wallet: wallet, payload: payload, eventId: eventId)
        }

        module.output.didFinish = { [weak bottomSheetViewController] in
            bottomSheetViewController?.dismiss()
        }

        module.output.didTapTransactionDetails = { [weak self] url, title in
            self?.openDapp(title: title, url: url)
        }
        if let fromViewController {
            bottomSheetViewController.present(fromViewController: fromViewController)
        } else {
            router.rootViewController.dismiss(animated: true) { [weak self] in
                guard let router = self?.router else { return }
                bottomSheetViewController.present(fromViewController: router.rootViewController)
            }
        }
    }

    func openTronEventDetails(
        wallet: Wallet,
        event: TronTransaction,
        network: Network,
        fromViewController: UIViewController?
    ) {
        let module = HistoryEventDetailsAssembly.module(
            wallet: wallet,
            event: .tron(event),
            keeperCoreAssembly: keeperCoreMainAssembly,
            network: network
        )
        let bottomSheetViewController = TKBottomSheetViewController(contentViewController: module.view)

        module.output.didFinish = { [weak bottomSheetViewController] in
            bottomSheetViewController?.dismiss()
        }

        module.output.didTapTransactionDetails = { [weak self] url, title in
            self?.openDapp(title: title, url: url)
        }

        if let fromViewController {
            bottomSheetViewController.present(fromViewController: fromViewController)
        } else {
            router.rootViewController.dismiss(animated: true) { [weak self] in
                guard let router = self?.router else { return }
                bottomSheetViewController.present(fromViewController: router.rootViewController)
            }
        }
    }

    func openBackup(wallet: Wallet) {
        guard let navigationController = router.rootViewController.navigationController else { return }
        let configuration = SettingsListBackupConfigurator(
            wallet: wallet,
            walletsStore: keeperCoreMainAssembly.storesAssembly.walletsStore,
            processedBalanceStore: keeperCoreMainAssembly.storesAssembly.processedBalanceStore,
            dateFormatter: keeperCoreMainAssembly.formattersAssembly.dateFormatter,
            amountFormatter: keeperCoreMainAssembly.formattersAssembly.amountFormatter
        )

        configuration.didTapBackupManually = { [weak self] in
            self?.openManuallyBackup(wallet: wallet)
        }

        configuration.didTapShowRecoveryPhrase = { [weak self] in
            self?.openRecoveryPhrase(wallet: wallet)
        }

        let module = SettingsListAssembly.module(configurator: configuration)
        module.viewController.setupBackButton()

        navigationController.pushViewController(module.viewController, animated: true)
    }

    func openBattery(
        wallet: Wallet,
        jettonMasterAddress: Address? = nil,
        keepCurrentModal: Bool = false
    ) {
        let navigationController = TKNavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)

        let coordinator = BatteryRefillCoordinator(
            router: NavigationControllerRouter(rootViewController: navigationController),
            wallet: wallet,
            jettonMasterAddress: jettonMasterAddress,
            coreAssembly: coreAssembly,
            keeperCoreMainAssembly: keeperCoreMainAssembly
        )

        coordinator.didOpenRefundURL = { [weak self] url, title in
            self?.openDapp(title: title, url: url)
        }

        coordinator.didRechargeSuccess = { [weak self] in
            self?.openHistory()
        }

        coordinator.didFinish = { [weak self, weak navigationController] in
            if keepCurrentModal {
                navigationController?.dismiss(animated: true)
            } else {
                self?.router.dismiss()
            }
            self?.removeChild($0)
        }

        self.batteryRefillCoordinator = coordinator

        addChild(coordinator)
        coordinator.start(deeplink: nil)

        if keepCurrentModal {
            self.router.presentOverTopPresented(
                navigationController,
                completion: {
                    coordinator.didAppear()
                },
                onDismiss: { [weak self, weak coordinator] in
                    self?.removeChild(coordinator)
                }
            )
        } else {
            self.router.dismiss(animated: true) { [weak self] in
                self?.router.present(
                    navigationController,
                    completion: {
                        coordinator.didAppear()
                    },
                    onDismiss: { [weak self, weak coordinator] in
                        self?.removeChild(coordinator)
                    }
                )
            }
        }
    }

    func openReceiveTRC20Popup(
        wallet: Wallet,
        enableCompletion: (() -> Void)? = nil
    ) {
        let module = ReceiveTRC20PopupAssembly.module(
            wallet: wallet,
            keeperCoreAssembly: keeperCoreMainAssembly,
            passcodeProvider: getPasscode
        )
        let bottomSheetViewController = TKBottomSheetViewController(contentViewController: module.view)
        bottomSheetViewController.present(fromViewController: router.rootViewController.topPresentedViewController())

        module.output.didFinish = { [weak bottomSheetViewController] in
            bottomSheetViewController?.dismiss()
        }

        module.output.didEnable = {
            enableCompletion?()
        }
    }

    func openRecoveryPhrase(wallet: Wallet) {
        guard let navigationController = router.rootViewController.navigationController else { return }
        let coordinator = SettingsRecoveryPhraseCoordinator(
            wallet: wallet,
            keeperCoreMainAssembly: keeperCoreMainAssembly,
            coreAssembly: coreAssembly,
            router: NavigationControllerRouter(rootViewController: navigationController)
        )

        coordinator.didFinish = { [weak self] in
            self?.removeChild($0)
        }

        addChild(coordinator)
        coordinator.start()
    }

    func openManuallyBackup(wallet: Wallet) {
        guard let navigationController = router.rootViewController.navigationController else { return }
        let coordinator = BackupModule(
            dependencies: BackupModule.Dependencies(
                keeperCoreMainAssembly: keeperCoreMainAssembly,
                coreAssembly: coreAssembly
            )
        ).createBackupCoordinator(
            router: NavigationControllerRouter(rootViewController: navigationController),
            wallet: wallet
        )

        coordinator.didFinish = { [weak self] in
            self?.removeChild($0)
        }

        addChild(coordinator)
        coordinator.start()
    }

    func openInsufficientFundsPopup(configuration: InfoPopupBottomSheetViewController.Configuration) {
        let viewController = InfoPopupBottomSheetViewController()
        let bottomSheetViewController = TKBottomSheetViewController(contentViewController: viewController)
        viewController.configuration = configuration
        router.dismiss(animated: true) { [router] in
            bottomSheetViewController.present(fromViewController: router.rootViewController)
        }
    }

    func openUnverifiedTokenInfoPopup() {
        AssetInfoPopupPresenter.presentUnverifiedToken(
            from: router.rootViewController.topPresentedViewController()
        )
    }

    func openDapp(title: String?, url: URL, isSilentConnect: Bool = false) {
        let dapp = Dapp(
            name: title ?? "",
            description: "",
            icon: nil,
            poster: nil,
            url: url,
            textColor: nil,
            excludeCountries: nil,
            includeCountries: nil
        )

        let controllerRouter = ViewControllerRouter(rootViewController: router.rootViewController)
        let coordinator = DappCoordinator(
            router: controllerRouter,
            dapp: dapp,
            isSilentConnect: isSilentConnect,
            coreAssembly: coreAssembly,
            keeperCoreMainAssembly: keeperCoreMainAssembly
        )

        coordinator.didHandleDeeplink = { [weak self] deeplink in
            _ = self?.handleTonkeeperDeeplink(deeplink, fromStories: false, sendSource: .deepLink)
        }

        addChild(coordinator)
        coordinator.start()
    }

    private nonisolated static var preservePresentedStackKey: String {
        "preservePresentedStack"
    }

    private func openHistory(fromNavigationController: UINavigationController? = nil) {
        let tradingUiEnabled = keeperCoreMainAssembly
            .configurationAssembly
            .configuration
            .featureEnabled(.tradingUiEnabled)

        if tradingUiEnabled {
            let coordinator = createHistoryCoordinator(navigationController: fromNavigationController)
            historyCoordinator.map(removeChild)
            historyCoordinator = coordinator
            addChild(coordinator)
            if fromNavigationController != nil {
                coordinator.start()
            } else {
                router.dismiss(animated: true) {
                    coordinator.start()
                }
            }
        } else {
            guard
                let historyViewController = historyCoordinator?.router.rootViewController,
                let index = router.rootViewController.viewControllers?.firstIndex(of: historyViewController)
            else {
                return
            }
            router.rootViewController.navigationController?.popToRootViewController(animated: true)
            router.rootViewController.selectedIndex = index
            router.dismiss(animated: true)
        }
    }

    private func openBrowserTab() {
        guard let browserViewController = browserCoordinator?.router.rootViewController else { return }
        _ = openDeeplinkTab(
            for: browserViewController
        )
    }

    private func openMainDeeplink() {
        deeplinkHandleTask?.cancel()
        deeplinkHandleTask = nil
        guard let walletViewController = walletCoordinator?.router.rootViewController else { return }
        _ = openDeeplinkTab(
            for: walletViewController
        )
    }

    private func openBrowserTabExplore() {
        openBrowserTab()
        browserCoordinator?.openExplore()
    }

    private func openBrowserDefiFlow() {
        openBrowserTab()
        browserCoordinator?.openDefi()
    }

    @discardableResult
    private func openTradeTab(completion: (() -> Void)? = nil) -> Bool {
        guard let tradeViewController = tradeCoordinator?.router.rootViewController else { return false }
        return openDeeplinkTab(
            for: tradeViewController,
            beforeTabSelect: { [weak self] in
                self?.tradeCoordinator?.openRoot(animated: false)
            },
            completion: completion
        )
    }

    @discardableResult
    private func openDeeplinkTab(
        for viewController: UIViewController,
        beforeTabSelect: (() -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) -> Bool {
        guard let index = router.rootViewController.viewControllers?.firstIndex(of: viewController) else {
            return false
        }
        router.rootViewController.navigationController?.popToRootViewController(animated: true)
        beforeTabSelect?()
        selectTab(at: index)
        if router.rootViewController.presentedViewController != nil {
            router.dismiss(animated: true, completion: completion)
        } else {
            completion?()
        }
        return true
    }

    private func selectTab(at index: Int) {
        router.rootViewController.selectedIndex = index
        playAnimatedTabBarItemIfNeeded(at: index)
    }

    private func playAnimatedTabBarItemIfNeeded(at index: Int) {
        guard keeperCoreMainAssembly.configurationAssembly.configuration.featureEnabled(.tradingUiEnabled) else {
            return
        }
        router.rootViewController.playAnimatedTabBarItem(at: index)
    }

    private func openTradingDeeplink(
        gridID: String?,
        source: TradeFlowAnalyticsSource
    ) -> Bool {
        guard openTradeTab(completion: { [weak self] in
            if let gridID {
                self?.tradeCoordinator?.scrollToGrid(id: gridID)
            }
        }) else {
            return false
        }

        coreAssembly.analyticsProvider.log(
            TradeStarted(from: source.tradeStarted)
        )
        return true
    }

    private func openTradeAssetDeeplink(
        assetID: String,
        source: AssetViewAnalyticsSource
    ) -> Bool {
        return openTradeTab { [weak self] in
            self?.tradeCoordinator?.openAssetDetails(
                assetID: assetID,
                source: source
            )
        }
    }

    private func tradeFlowAnalyticsSource(for sendSource: SendAnalyticsSource) -> TradeFlowAnalyticsSource {
        switch sendSource {
        case .qrCode:
            .qrCode
        default:
            .deepLink
        }
    }

    private func depositAnalyticsSource(for sendSource: SendAnalyticsSource) -> DepositAnalyticsSource {
        switch sendSource {
        case .qrCode:
            .qrCode
        default:
            .deepLink
        }
    }

    private func assetViewAnalyticsSource(for sendSource: SendAnalyticsSource) -> AssetViewAnalyticsSource {
        switch sendSource {
        case .qrCode:
            .qrCode
        default:
            .deepLink
        }
    }

    private func decryptComment(
        wallet: Wallet,
        payload: EncryptedCommentPayload,
        eventId: String
    ) {
        DecryptCommentHandler.decryptComment(
            wallet: wallet,
            payload: payload,
            eventId: eventId,
            parentCoordinator: self,
            parentRouter: router,
            keeperCoreAssembly: keeperCoreMainAssembly,
            coreAssembly: coreAssembly
        )
    }

    private func getPasscode() async -> String? {
        return await PasscodeInputCoordinator.getPasscode(
            parentCoordinator: self,
            parentRouter: router,
            mnemonicAccess: keeperCoreMainAssembly.mnemonicAccess,
            securityStore: keeperCoreMainAssembly.storesAssembly.securityStore
        )
    }

    private func didOpenAppWithPushNotificationTapHandler(userInfo: [AnyHashable: Any]?) {
        let pushId = userInfo?["push_id"] as? String
        let link = userInfo?["link"] as? String
        let dappUrl = userInfo?["dapp_url"] as? String
        let deeplink = userInfo?["deeplink"] as? String

        let resolvedDeeplink: String?
        if let link, let linkURL = URL(string: link) {
            resolvedDeeplink = link
            openURL(linkURL, title: nil)
        } else if let dappUrl, let dappUrlURL = URL(string: dappUrl) {
            resolvedDeeplink = dappUrl
            openURL(dappUrlURL, title: nil)
        } else {
            let deeplink = link ?? dappUrl ?? deeplink
            resolvedDeeplink = deeplink
            _ = self.handleDeeplink(deeplink: deeplink, fromStories: false)
        }

        coreAssembly.analyticsProvider.log(PushClick(
            pushId: pushId,
            deepLink: resolvedDeeplink.map(Self.removePrivateDataFromUrl)
        ))
    }

    private static let regexPrivateData = try! NSRegularExpression(pattern: "[a-fA-F0-9]{64}|0:[a-fA-F0-9]{64}")

    private static func removePrivateDataFromUrl(_ url: String) -> String {
        let range = NSRange(url.startIndex..., in: url)
        return regexPrivateData.stringByReplacingMatches(in: url, range: range, withTemplate: "X")
    }
}

// MARK: - Ton Connect

// MARK: - AppStateTrackerObserver

extension MainCoordinator: AppStateTrackerObserver {
    func didUpdateState(_ state: TKCore.AppStateTracker.State) {
        switch (appStateTracker.state, reachabilityTracker.state) {
        case (.active, .connected):
            mainController.startUpdates()
        case (.background, _):
            mainController.stopUpdates()
        default: return
        }
    }
}

// MARK: - ReachabilityTrackerObserver

extension MainCoordinator: ReachabilityTrackerObserver {
    func didUpdateState(_ state: TKCore.ReachabilityTracker.State) {
        switch reachabilityTracker.state {
        case .connected:
            mainController.startUpdates()
        default:
            return
        }
    }
}
