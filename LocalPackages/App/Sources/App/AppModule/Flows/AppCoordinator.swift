import KeeperCore
import TKCoordinator
import TKCore
import TKFeatureFlags
import TKUIKit
import UIKit
import WidgetKit

public final class AppCoordinator: RouterCoordinator<WindowRouter> {
    let coreAssembly: TKCore.CoreAssembly
    let keeperCoreAssembly: KeeperCore.Assembly

    private let appStateTracker: AppStateTracker

    private weak var rootCoordinator: RootCoordinator?

    public init(
        router: WindowRouter,
        coreAssembly: TKCore.CoreAssembly
    ) {
        self.coreAssembly = coreAssembly
        self.keeperCoreAssembly = KeeperCore.Assembly(
            dependencies: Assembly.Dependencies(
                cacheURL: coreAssembly.cacheURL,
                sharedCacheURL: coreAssembly.sharedCacheURL,
                appInfoProvider: coreAssembly.appInfoProvider,
                featureFlags: coreAssembly.featureFlags,
                tkAppSettings: coreAssembly.tkAppSettings,
                seedProvider: coreAssembly.seedProvider,
                firebaseUserIdProvider: { coreAssembly.uniqueIdProvider.uniqueDeviceId.uuidString }
            )
        )
        self.appStateTracker = coreAssembly.appStateTracker
        super.init(router: router)
    }

    override public func start(deeplink: CoordinatorDeeplink? = nil) {
        makeTKUIKitInitialSetup()

        var settingsRepository = keeperCoreAssembly.repositoriesAssembly.settingsRepository()
        if settingsRepository.isFirstRun {
            settingsRepository.isFirstRun = false
            settingsRepository.seed = UUID().uuidString
        }

        openRoot(deeplink: deeplink)

        appStateTracker.addObserver(self)

        coreAssembly.analyticsProvider.log(
            LaunchApp(theme: TKThemeManager.shared.theme.analyticsTheme),
            featureFlags: coreAssembly.featureFlags.asDictionary().asJsonString()
        )
    }

    override public func handleDeeplink(deeplink: CoordinatorDeeplink?) -> Bool {
        guard let rootCoordinator else { return false }
        return rootCoordinator.handleDeeplink(deeplink: deeplink)
    }

    private func makeTKUIKitInitialSetup() {
        ToastPresenter.windowLevel = .toast
    }
}

private extension AppCoordinator {
    func openRoot(deeplink: TKCoordinator.CoordinatorDeeplink? = nil) {
        let rootCoordinator = RootCoordinator(
            router: ViewControllerRouter(rootViewController: AppCoordinatorRootViewController()),
            dependencies: RootCoordinator.Dependencies(
                coreAssembly: coreAssembly,
                keeperCoreRootAssembly: keeperCoreAssembly.rootAssembly()
            )
        )
        self.router.window.rootViewController = rootCoordinator.router.rootViewController

        self.rootCoordinator = rootCoordinator

        addChild(rootCoordinator)
        rootCoordinator.start(deeplink: deeplink)
    }
}

extension AppCoordinator: AppStateTrackerObserver {
    public func didUpdateState(_ state: AppStateTracker.State) {
        switch state {
        case .resign:
            WidgetCenter.shared.reloadAllTimelines()
        default:
            break
        }
    }
}

class AppCoordinatorRootViewController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}

private extension TKTheme {
    var analyticsTheme: LaunchApp.Theme {
        switch self {
        case .deepBlue: return .deepBlue
        case .dark: return .dark
        case .light: return .light
        case .system:
            return UIScreen.main.traitCollection.userInterfaceStyle == .dark
                ? .systemDark
                : .systemLight
        }
    }
}
