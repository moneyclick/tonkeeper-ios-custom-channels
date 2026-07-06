import KeeperCore
import TKCoordinator
import TKCore
import TKUIKit

@MainActor
struct MainModule {
    private let dependencies: Dependencies
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func createMainCoordinator() -> MainCoordinator {
        let tabBarController = TKTabBarController()
        tabBarController.configureAppearance()
        let inAppReviewService = InAppReviewServiceImplementation(
            featureFlags: dependencies.coreAssembly.featureFlags,
            analyticsProvider: dependencies.coreAssembly.analyticsProvider,
            firstLaunchDate: dependencies.coreAssembly.appSettings.firstLaunchDate,
            appVersion: dependencies.coreAssembly.appInfoProvider.version
        )

        return MainCoordinator(
            router: TabBarControllerRouter(rootViewController: tabBarController),
            coreAssembly: dependencies.coreAssembly,
            keeperCoreMainAssembly: dependencies.keeperCoreMainAssembly,
            appStateTracker: dependencies.coreAssembly.appStateTracker,
            reachabilityTracker: dependencies.coreAssembly.reachabilityTracker,
            recipientResolver: dependencies.keeperCoreMainAssembly.loadersAssembly.recipientResolver(),
            insufficientFundsValidator: dependencies.keeperCoreMainAssembly.loadersAssembly.insufficientFundsValidator(),
            inAppReviewService: inAppReviewService,
            depositPendingTracker: dependencies.depositPendingTracker
        )
    }
}

extension MainModule {
    struct Dependencies {
        let coreAssembly: TKCore.CoreAssembly
        let keeperCoreMainAssembly: KeeperCore.MainAssembly
        let depositPendingTracker: DepositPendingTracker

        init(
            coreAssembly: TKCore.CoreAssembly,
            keeperCoreMainAssembly: KeeperCore.MainAssembly,
            depositPendingTracker: DepositPendingTracker
        ) {
            self.coreAssembly = coreAssembly
            self.keeperCoreMainAssembly = keeperCoreMainAssembly
            self.depositPendingTracker = depositPendingTracker
        }
    }
}
