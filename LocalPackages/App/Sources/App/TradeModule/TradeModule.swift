import KeeperCore
import TKCoordinator
import TKCore
import TKLogging
import TKUIKit
import UIKit

@MainActor
struct TradeModule {
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func createTradeCoordinator(
        output: CoordinatorOutput
    ) -> TradeCoordinator {
        Log.trade.i("init coordinator")
        let navigationController = TKNavigationController()
        navigationController.configureTransparentAppearance()
        navigationController.setNavigationBarHidden(true, animated: false)

        return TradeCoordinator(
            router: NavigationControllerRouter(rootViewController: navigationController),
            coreAssembly: dependencies.coreAssembly,
            keeperCoreMainAssembly: dependencies.keeperCoreMainAssembly,
            jettonService: dependencies.keeperCoreMainAssembly.servicesAssembly.jettonService(),
            shelvesService: dependencies.keeperCoreMainAssembly.servicesAssembly.tradingShelvesService(),
            assetsListService: dependencies.keeperCoreMainAssembly.servicesAssembly.assetsListService(),
            assetDetailsService: dependencies.keeperCoreMainAssembly.servicesAssembly.assetDetailsService(),
            balanceService: dependencies.keeperCoreMainAssembly.servicesAssembly.balanceService(),
            ratesService: dependencies.keeperCoreMainAssembly.servicesAssembly.ratesService(),
            currencyStore: dependencies.keeperCoreMainAssembly.storesAssembly.currencyStore,
            amountFormatter: dependencies.keeperCoreMainAssembly.formattersAssembly.amountFormatter,
            signedAmountFormatter: dependencies.keeperCoreMainAssembly.formattersAssembly.signedAmountFormatter,
            chartViewStateProvider: { chartIdentifier in
                ChartAssembly
                    .viewState(
                        chartController: dependencies.keeperCoreMainAssembly.chartV2Controller(
                            chartIdentifier: chartIdentifier
                        ),
                        coreAssembly: dependencies.coreAssembly,
                        keeperCoreMainAssembly: dependencies.keeperCoreMainAssembly
                    )
            },
            output: output
        )
    }
}

extension TradeModule {
    enum SwapContext {
        case ton(
            from: TonToken,
            to: TonToken,
            fromCategory: TradingAssetCategory? = nil,
            toCategory: TradingAssetCategory? = nil
        )
        case tron
    }

    struct CoordinatorOutput {
        var onSwap: (SwapContext, Wallet, UINavigationController?) -> Void
        var onSend: (Wallet, Token, UINavigationController?) -> Void
        var onReceive: ([Token], Wallet, UINavigationController?) -> Void
        var onOpenStaking: (Wallet) -> Void
        var onOpenHistoryEvent: (TradeAssetHistorySelection, UINavigationController?) -> Void
        var tokenDetailsConfiguratorProvider: (Wallet, Token) -> TokenDetailsConfigurator?
        var onOpenUnverifiedTokenInfoPopup: (UINavigationController?) -> Void
        var onOpenUrl: (URL, UINavigationController?) -> Void
    }
}

extension TradeModule {
    struct Dependencies {
        let coreAssembly: TKCore.CoreAssembly
        let keeperCoreMainAssembly: KeeperCore.MainAssembly

        init(
            coreAssembly: TKCore.CoreAssembly,
            keeperCoreMainAssembly: KeeperCore.MainAssembly
        ) {
            self.coreAssembly = coreAssembly
            self.keeperCoreMainAssembly = keeperCoreMainAssembly
        }
    }
}
