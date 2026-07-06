import KeeperCore
import TKCoordinator
import TKCore
import TKLogging
import TKStories
import TKUIKit
import TonSwift
import UIKit

final class RootCoordinator: RouterCoordinator<ViewControllerRouter> {
    struct Dependencies {
        let coreAssembly: TKCore.CoreAssembly
        let keeperCoreRootAssembly: KeeperCore.RootAssembly
    }

    private weak var onboardingCoordinator: OnboardingCoordinator?
    private weak var mainCoordinator: MainCoordinator?

    private var activeViewController: UIViewController?

    private let dependencies: Dependencies
    private let rootController: RootController

    private let stateManager: RootCoordinatorStateManager
    private let pushNotificationsManager: PushNotificationManager
    private let brokenTronWalletAnalyticsTracker: BrokenTronWalletAnalyticsCounter
    private let mnemonicDerivationAnalyticsTracker: MnemonicDerivationAnalyticsCounter
    private let argon2DeriveTimeMeasurementController: Argon2DeriveTimeMeasurementController
    private let batteryChargedAnalyticsObserver: BatteryChargedAnalyticsObserver
    private let depositCompletedAnalyticsObserver: DepositCompletedAnalyticsObserver
    private let depositPendingTracker: DepositPendingTracker

    init(
        router: ViewControllerRouter,
        dependencies: Dependencies
    ) {
        self.dependencies = dependencies
        self.rootController = dependencies.keeperCoreRootAssembly.rootController()
        self.stateManager = RootCoordinatorStateManager(
            walletsStore: dependencies.keeperCoreRootAssembly.storesAssembly.walletsStore
        )
        self.pushNotificationsManager = PushNotificationManager(
            appSettings: dependencies.coreAssembly.appSettings,
            uniqueIdProvider: dependencies.coreAssembly.uniqueIdProvider,
            pushNotificationTokenProvider: dependencies.coreAssembly.pushNotificationTokenProvider,
            pushNotificationAPI: dependencies.keeperCoreRootAssembly.mainAssembly().apiAssembly.pushNotificationsAPI,
            walletNotificationsStore: dependencies.keeperCoreRootAssembly.storesAssembly.walletNotificationStore,
            tonConnectAppsStore: dependencies.keeperCoreRootAssembly.mainAssembly().tonConnectAssembly.tonConnectAppsStore,
            tonProofTokenService: dependencies.keeperCoreRootAssembly.servicesAssembly.tonProofTokenService()
        )
        self.brokenTronWalletAnalyticsTracker = BrokenTronWalletAnalyticsCounter(
            walletsUpdateAssembly: dependencies.keeperCoreRootAssembly.walletsUpdateAssembly,
            analyticsProvider: dependencies.coreAssembly.analyticsProvider
        )
        self.mnemonicDerivationAnalyticsTracker = MnemonicDerivationAnalyticsCounter(
            walletsUpdateAssembly: dependencies.keeperCoreRootAssembly.walletsUpdateAssembly,
            analyticsProvider: dependencies.coreAssembly.analyticsProvider
        )
        self.argon2DeriveTimeMeasurementController = Argon2DeriveTimeMeasurementController(
            analyticsProvider: dependencies.coreAssembly.analyticsProvider,
            appInfoProvider: dependencies.coreAssembly.appInfoProvider
        )
        self.batteryChargedAnalyticsObserver = BatteryChargedAnalyticsObserver(
            totalBalanceStore: dependencies.keeperCoreRootAssembly.storesAssembly.totalBalanceStore,
            analyticsProvider: dependencies.coreAssembly.analyticsProvider
        )
        let depositPendingTracker = DepositPendingTracker()
        self.depositPendingTracker = depositPendingTracker
        self.depositCompletedAnalyticsObserver = DepositCompletedAnalyticsObserver(
            totalBalanceStore: dependencies.keeperCoreRootAssembly.storesAssembly.totalBalanceStore,
            depositPendingTracker: depositPendingTracker,
            analyticsProvider: dependencies.coreAssembly.analyticsProvider
        )
        super.init(router: router)
    }

    override func start(deeplink: CoordinatorDeeplink? = nil) {
        pushNotificationsManager.setup()
        rootController.loadConfigurations()

        stateManager.didUpdateState = { [weak self] state in
            self?.handleStateUpdate(state: state, deeplink: deeplink)
        }

        let state = stateManager.state
        switch state {
        case .onboarding:
            migrateRNIfNeed(deeplink: deeplink) { [weak self] isSuccess in
                if isSuccess {
                    self?.stateManager.didPerformRNMigration()
                } else {
                    self?.openOnboarding(deeplink: deeplink)
                }
            }
        case .main:
            migrateNativeIfNeed { [weak self] didNeedToMigrate, isSuccess in
                if !isSuccess {
                    self?.openOnboarding(deeplink: deeplink)
                    return
                }
                if didNeedToMigrate {
                    self?.openMain(deeplink: deeplink)
                } else {
                    self?.handlePasscodeFlowIfNeeded {
                        self?.openMain(deeplink: deeplink)
                    }
                }
            }
        }
        sendFirstLaunchAnalyticsEvent()
    }

    override func handleDeeplink(deeplink: CoordinatorDeeplink?) -> Bool {
        guard let string = deeplink as? String else { return false }
        do {
            let coreDeeplink = try rootController.parseDeeplink(string: string)
            if let onboardingCoordinator {
                return onboardingCoordinator.handleDeeplink(deeplink: coreDeeplink)
            } else if let mainCoordinator {
                return mainCoordinator.handleDeeplink(deeplink: coreDeeplink, fromStories: false)
            } else {
                return false
            }
        } catch {
            ToastPresenter.showToast(configuration: .defaultConfiguration(text: error.localizedDescription))
            return false
        }
    }

    private func handlePasscodeFlowIfNeeded(completion: @escaping (() -> Void)) {
        let isLockScreen = dependencies.keeperCoreRootAssembly.storesAssembly.securityStore.getState().isLockScreen
        let tonProofTokenService = dependencies.keeperCoreRootAssembly.mainAssembly().servicesAssembly.tonProofTokenService()
        let mnemonicAccess = dependencies.keeperCoreRootAssembly.secureAssembly.mnemonicAccess
        let missedTonProofWallets = tonProofTokenService.getWalletsWithMissedToken()

        guard isLockScreen
            || !missedTonProofWallets.isEmpty
            || brokenTronWalletAnalyticsTracker.needsStartupCheck
            || mnemonicDerivationAnalyticsTracker.needsStartupCheck
        else {
            completion()
            return
        }

        showPasscode(validator: PasscodeConfirmationValidator(mnemonicAccess: mnemonicAccess)) { [brokenTronWalletAnalyticsTracker, mnemonicDerivationAnalyticsTracker] passcode in
            Task {
                await brokenTronWalletAnalyticsTracker.countWalletsAtStartupIfNeeded(passcode: passcode)
                await mnemonicDerivationAnalyticsTracker.countWalletsAtStartupIfNeeded(passcode: passcode)
            }
            guard !missedTonProofWallets.isEmpty else {
                completion()
                return
            }
            Task {
                for wallet in missedTonProofWallets {
                    do {
                        let mnemonic = try await mnemonicAccess.getMnemonic(wallet: wallet, passcode: passcode)
                        let keyPair = try mnemonic.toKeyPair()
                        let pair = WalletPrivateKeyPair(
                            wallet: wallet,
                            privateKey: keyPair.privateKey
                        )
                        await tonProofTokenService.loadTokensFor(pairs: [pair])
                    } catch {
                        Log.e("🪵 failed to load mnemonic for TonProof (v2): \(error)")
                        continue
                    }
                }
                await MainActor.run {
                    completion()
                }
            }
        }
    }

    private func showPasscode(
        validator: PasscodeInputValidator,
        completion: ((String) -> Void)?
    ) {
        let router = NavigationControllerRouter(rootViewController: TKNavigationController())

        let securityStore = dependencies.keeperCoreRootAssembly.storesAssembly.securityStore
        let passcodeBiometry = PasscodeBiometryProvider(
            biometryProvider: BiometryProvider(),
            securityStore: securityStore
        )
        let coordinator = PasscodeInputCoordinator(
            router: router,
            context: .entry,
            validator: validator,
            biometryProvider: passcodeBiometry,
            securityStore: securityStore
        )

        coordinator.didInputPasscode = { [weak self, weak coordinator] passcode in
            self?.removeChild(coordinator)
            completion?(passcode)
        }

        coordinator.didLogout = { [dependencies, weak coordinator] in
            guard let coordinator else { return }
            let deleteController = dependencies.keeperCoreRootAssembly.mainAssembly().walletDeleteController
            Task {
                await deleteController.deleteAll()
                await MainActor.run {
                    self.removeChild(coordinator)
                }
            }
        }

        coordinator.start()
        addChild(coordinator)

        showViewController(coordinator.router.rootViewController, animated: false)
    }
}

private extension RootCoordinator {
    func handleStateUpdate(state: RootCoordinatorStateManager.State, deeplink: CoordinatorDeeplink? = nil) {
        removeChild(mainCoordinator)
        removeChild(onboardingCoordinator)
        self.mainCoordinator = nil
        self.onboardingCoordinator = nil
        switch state {
        case .onboarding:
            openOnboarding(deeplink: deeplink)
        case .main:
            openMain(deeplink: deeplink)
        }
    }

    func openOnboarding(deeplink: CoordinatorDeeplink?) {
        let module = OnboardingModule(
            dependencies: OnboardingModule.Dependencies(
                coreAssembly: dependencies.coreAssembly,
                keeperCoreOnboardingAssembly: dependencies.keeperCoreRootAssembly.onboardingAssembly(),
                configurationAssembly: dependencies.keeperCoreRootAssembly.mainAssembly().configurationAssembly
            )
        )
        let coordinator = module.createOnboardingCoordinator()

        coordinator.didFinishOnboarding = { [weak self, weak coordinator] in
            self?.onboardingCoordinator = nil
            guard let coordinator = coordinator else { return }
            self?.removeChild(coordinator)
        }

        self.onboardingCoordinator = coordinator

        addChild(coordinator)
        coordinator.start(deeplink: deeplink)

        showViewController(coordinator.router.rootViewController, animated: true)
    }

    func openMain(deeplink: CoordinatorDeeplink?) {
        let module = MainModule(
            dependencies: MainModule.Dependencies(
                coreAssembly: dependencies.coreAssembly,
                keeperCoreMainAssembly: dependencies.keeperCoreRootAssembly.mainAssembly(),
                depositPendingTracker: depositPendingTracker
            )
        )
        let coordinator = module.createMainCoordinator()
        self.mainCoordinator = coordinator

        addChild(coordinator)
        coordinator.start(deeplink: deeplink)

        let navigationController = TKNavigationController(rootViewController: coordinator.router.rootViewController)
        navigationController.configureDefaultAppearance()

        showViewController(navigationController, animated: true)
        Task {
            await argon2DeriveTimeMeasurementController.runInBackgroundIfNeeded()
        }
    }

    func handleMigrationResult(
        _ result: MergeMigration.MigrationResult,
        completion: @escaping (_ isSuccess: Bool) -> Void
    ) {
        let title: String
        var description: String
        switch result {
        case let .failedMigrateMnemonics(error):
            title = "Migration failed"
            description = "Failed migrate mnemonics \(error.localizedDescription)"
            completion(false)
        case let .failedMigrateWallets(error):
            title = "Migration failed"
            description = "Failed migrate wallets \(error.localizedDescription)"
            completion(false)
        case let .partialy(failedWallets):
            title = "Failed migrate some wallets"
            description = failedWallets.map { "Name: \($0.name)\nType: \($0.type), \nPublicKey: \($0.pubkey)" }.joined(separator: "\n\n")
            completion(true)
        case .success:
            completion(true)
            return
        }

        description += "\n\n Your seed phrases are safe!"

        let alertController = UIAlertController(
            title: title,
            message: description,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default))

        router.rootViewController.topPresentedViewController().present(alertController, animated: true)
    }

    func migrateNativeIfNeed(completion: @escaping (_ didNeedToMigrate: Bool, _ isSuccess: Bool) -> Void) {
        let secureAssembly = dependencies.keeperCoreRootAssembly.secureAssembly
        let mergeMigration = MergeMigration(
            asyncStorage: dependencies.keeperCoreRootAssembly.rnAssembly.rnAsyncStorage,
            appInfoProvider: dependencies.coreAssembly.appInfoProvider,
            mnemonicsAccess: secureAssembly.mnemonicAccess,
            keeperInfoRepository: dependencies.keeperCoreRootAssembly.repositoriesAssembly.keeperInfoRepository(),
            keeperInfoStore: dependencies.keeperCoreRootAssembly.storesAssembly.keeperInfoStore,
            securityStore: dependencies.keeperCoreRootAssembly.storesAssembly.securityStore,
            tonProofTokenService: dependencies.keeperCoreRootAssembly.servicesAssembly.tonProofTokenService()
        )

        let (needsMigrate, currentVersion) = mergeMigration.currentMnemonicsVersion()
        guard needsMigrate else {
            completion(false, true)
            return
        }
        mergeMigration.performNativeMigration(from: currentVersion) { [weak self] handler in
            guard let self else { return }
            showPasscode(validator: handler.validator) { passcode in
                handler.onSuccess(passcode)
            }
        } completion: { [weak self] result in
            self?.handleMigrationResult(result, completion: { isSuccess in
                completion(true, isSuccess)
            })
        }
    }

    func migrateRNIfNeed(deeplink: CoordinatorDeeplink?, completion: @escaping (_ isSuccess: Bool) -> Void) {
        let mergeMigration = MergeMigration(
            asyncStorage: dependencies.keeperCoreRootAssembly.rnAssembly.rnAsyncStorage,
            appInfoProvider: dependencies.coreAssembly.appInfoProvider,
            mnemonicsAccess: dependencies.keeperCoreRootAssembly.secureAssembly.mnemonicAccess,
            keeperInfoRepository: dependencies.keeperCoreRootAssembly.repositoriesAssembly.keeperInfoRepository(),
            keeperInfoStore: dependencies.keeperCoreRootAssembly.storesAssembly.keeperInfoStore,
            securityStore: dependencies.keeperCoreRootAssembly.storesAssembly.securityStore,
            tonProofTokenService: dependencies.keeperCoreRootAssembly.servicesAssembly.tonProofTokenService()
        )

        Task { @MainActor [weak self] in
            guard let self else { return }
            guard await mergeMigration.isNeedToMigrateFromRN() else {
                openOnboarding(deeplink: deeplink)
                return
            }

            let result = await mergeMigration.performRNMigration { [weak self] handler in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.showPasscode(validator: handler.validator) { [weak self] passcode in
                        Task { [weak self] in
                            guard let self else { return }
                            await brokenTronWalletAnalyticsTracker.countWalletsAtStartupIfNeeded(passcode: passcode)
                            await mnemonicDerivationAnalyticsTracker.countWalletsAtStartupIfNeeded(passcode: passcode)
                        }
                        handler.onSuccess(passcode)
                    }
                }
            }
            handleMigrationResult(result) { isSuccess in
                completion(isSuccess)
            }
        }
    }

    func showViewController(_ viewController: UIViewController, animated: Bool) {
        activeViewController?.willMove(toParent: nil)
        activeViewController?.view.removeFromSuperview()
        activeViewController?.removeFromParent()

        activeViewController = viewController

        router.rootViewController.addChild(viewController)
        router.rootViewController.view.addSubview(viewController.view)
        viewController.didMove(toParent: router.rootViewController)

        viewController.view.snp.makeConstraints { make in
            make.edges.equalTo(router.rootViewController.view)
        }

        if animated {
            UIView.transition(with: router.rootViewController.view, duration: 0.2, options: .transitionCrossDissolve) {}
        }
    }

    func sendFirstLaunchAnalyticsEvent() {
        let analyticsProvider = dependencies.coreAssembly.analyticsProvider
        let appSettings = dependencies.coreAssembly.appSettings

        let firstLaunchTimestamp = appSettings.firstLaunchDate
        guard firstLaunchTimestamp == nil else { return }
        appSettings.firstLaunchDate = Date()

        analyticsProvider.log(InstallApp())
    }
}

extension KeeperCore.Deeplink: TKCoordinator.CoordinatorDeeplink {}
extension String: TKCoordinator.CoordinatorDeeplink {}
