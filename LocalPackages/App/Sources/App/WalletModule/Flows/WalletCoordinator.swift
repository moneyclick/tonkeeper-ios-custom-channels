import KeeperCore
import TKCoordinator
import TKCore
import TKLocalize
import TKUIKit
import UIKit

public final class WalletCoordinator: RouterCoordinator<NavigationControllerRouter> {
    var didTapScan: (() -> Void)?
    var didLogout: (() -> Void)?
    var didTapWalletButton: (() -> Void)?
    var didTapWithdraw: ((Wallet) -> Void)?
    var didTapDeposit: ((Wallet) -> Void)?
    var didTapSwap: ((Wallet) -> Void)?
    var didTapStake: ((Wallet) -> Void)?
    var didTapSettingsButton: ((Wallet) -> Void)?
    var didTapHistoryButton: (() -> Void)?
    var didSelectTonDetails: ((Wallet) -> Void)?
    var didSelectJettonDetails: ((Wallet, JettonItem, Bool) -> Void)?
    var didSelectTronUSDTDetails: ((Wallet) -> Void)?
    var didSelectEthenaDetails: ((Wallet) -> Void)?
    var didSelectStakingItem: ((
        _ wallet: Wallet,
        _ stakingPoolInfo: StackingPoolInfo,
        _ accountStakingInfo: AccountStackingInfo
    ) -> Void)?
    var didSelectCollectStakingItem: ((
        _ wallet: Wallet,
        _ stakingPoolInfo: StackingPoolInfo,
        _ accountStakingInfo: AccountStackingInfo
    ) -> Void)?
    var didTapBackup: ((Wallet) -> Void)?
    var didTapBattery: ((Wallet) -> Void)?
    var didRequestDeeplinkHandling: ((Deeplink) -> Void)?
    var didTapOpenCryptoAssets: (() -> Void)?

    private let coreAssembly: TKCore.CoreAssembly
    private let keeperCoreMainAssembly: KeeperCore.MainAssembly
    private weak var walletContainerViewController: WalletContainerViewController?

    var historyButtonTooltipSourceView: UIView? {
        walletContainerViewController?.historyButtonTooltipSourceView
    }

    private var configuration: Configuration {
        keeperCoreMainAssembly.configurationAssembly.configuration
    }

    init(
        router: NavigationControllerRouter,
        coreAssembly: TKCore.CoreAssembly,
        keeperCoreMainAssembly: KeeperCore.MainAssembly
    ) {
        self.coreAssembly = coreAssembly
        self.keeperCoreMainAssembly = keeperCoreMainAssembly
        super.init(router: router)
        router.rootViewController.tabBarItem.title = TKLocales.Tabs.wallet
        router.rootViewController.tabBarItem.image = .TKUIKit.Icons.Size28.wallet
    }

    override public func start() {
        openWalletContainer()
    }
}

private extension WalletCoordinator {
    func openWalletContainer() {
        let module = WalletContainerAssembly.module(
            walletBalanceModule: createWalletBalanceModule(),
            walletsStore: keeperCoreMainAssembly.storesAssembly.walletsStore,
            configuration: configuration
        )
        walletContainerViewController = module.view

        module.output.walletButtonHandler = { [weak self] in
            self?.didTapWalletButton?()
        }

        module.output.didTapScan = { [weak self] in
            self?.didTapScan?()
        }

        module.output.didTapSettingsButton = { [weak self] wallet in
            self?.didTapSettingsButton?(wallet)
        }

        module.output.didTapHistoryButton = { [weak self] in
            self?.didTapHistoryButton?()
        }

        router.push(viewController: module.view, animated: false)
    }

    func openManageTokens(wallet: Wallet) {
        let updateQueue = DispatchQueue(label: "ManageTokensQueue")

        let module = ManageTokensAssembly.module(
            model: ManageTokensModel(
                wallet: wallet,
                tokenManagementStore: keeperCoreMainAssembly.storesAssembly.tokenManagementStore,
                convertedBalanceStore: keeperCoreMainAssembly.storesAssembly.convertedBalanceStore,
                stackingPoolsStore: keeperCoreMainAssembly.storesAssembly.stackingPoolsStore,
                updateQueue: updateQueue
            ),
            mapper: ManageTokensListMapper(amountFormatter: keeperCoreMainAssembly.formattersAssembly.amountFormatter),
            updateQueue: updateQueue,
            configuration: keeperCoreMainAssembly.configurationAssembly.configuration
        )

        let navigationController = TKNavigationController(rootViewController: module.view)
        navigationController.setNavigationBarHidden(true, animated: false)

        router.present(navigationController)
    }

    @MainActor
    func createWalletBalanceModule() -> WalletBalanceModule {
        let module = WalletBalanceAssembly.module(
            keeperCoreMainAssembly: keeperCoreMainAssembly,
            coreAssembly: coreAssembly
        )

        module.output.didSelectTon = { [weak self] wallet in
            self?.didSelectTonDetails?(wallet)
        }

        module.output.didSelectJetton = { [weak self] wallet, jettonItem, hasPrice in
            self?.didSelectJettonDetails?(wallet, jettonItem, hasPrice)
        }

        module.output.didSelectTronUSDT = { [weak self] wallet in
            self?.didSelectTronUSDTDetails?(wallet)
        }

        module.output.didSelectEthena = { [weak self] wallet in
            self?.didSelectEthenaDetails?(wallet)
        }

        module.output.didSelectStakingItem = { [weak self] wallet, stakingPoolInfo, accountStackingInfo in
            self?.didSelectStakingItem?(wallet, stakingPoolInfo, accountStackingInfo)
        }

        module.output.didSelectCollectStakingItem = { [weak self] wallet, stakingPoolInfo, accountStackingInfo in
            self?.didSelectCollectStakingItem?(wallet, stakingPoolInfo, accountStackingInfo)
        }

        module.output.didTapWithdraw = { [weak self] wallet in
            self?.didTapWithdraw?(wallet)
        }

        module.output.didTapDeposit = { [weak self] wallet in
            self?.didTapDeposit?(wallet)
        }

        module.output.didTapSwap = { [weak self] wallet in
            self?.didTapSwap?(wallet)
        }

        module.output.didTapStake = { [weak self] wallet in
            self?.didTapStake?(wallet)
        }

        module.output.didTapBackup = { [weak self] wallet in
            self?.didTapBackup?(wallet)
        }

        module.output.didTapBattery = { [weak self] wallet in
            self?.didTapBattery?(wallet)
        }

        module.output.didTapManage = { [weak self] wallet in
            self?.openManageTokens(wallet: wallet)
        }

        module.output.didTapOpenCryptoAssets = { [weak self] in
            self?.didTapOpenCryptoAssets?()
        }

        module.output.didRequirePasscode = { [weak self] in
            await self?.getPasscode()
        }

        let homeBannersViewModel = module.output.homeBannersViewModel
        homeBannersViewModel.onOpenDeeplink = { [weak self] deeplink in
            self?.didRequestDeeplinkHandling?(deeplink)
        }

        return module
    }

    func getPasscode() async -> String? {
        return await PasscodeInputCoordinator.getPasscode(
            parentCoordinator: self,
            parentRouter: router,
            mnemonicAccess: keeperCoreMainAssembly.mnemonicAccess,
            securityStore: keeperCoreMainAssembly.storesAssembly.securityStore
        )
    }
}
