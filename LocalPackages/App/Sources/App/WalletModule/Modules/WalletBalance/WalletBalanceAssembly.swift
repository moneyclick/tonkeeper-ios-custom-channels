import Foundation
import KeeperCore
import TKAppInfo
import TKCore
import UIKit

typealias WalletBalanceModule = MVVMModule<WalletBalanceViewController, WalletBalanceModuleOutput, WalletBalanceModuleInput>

struct WalletBalanceAssembly {
    private init() {}
    @MainActor
    static func module(
        keeperCoreMainAssembly: KeeperCore.MainAssembly,
        coreAssembly: TKCore.CoreAssembly
    ) -> WalletBalanceModule {
        let queue = DispatchQueue(label: "WalletBalanceUpdateQueue")

        let balanceItemMapper = BalanceItemMapper(
            amountFormatter: keeperCoreMainAssembly.formattersAssembly.amountFormatter
        )

        let stakingMappper = WalletBalanceListStakingMapper(
            amountFormatter: keeperCoreMainAssembly.formattersAssembly.amountFormatter,
            balanceItemMapper: balanceItemMapper
        )
        let tradeAssetDetailsValueFormatter = TradeAssetDetailsValueFormatter(
            amountFormatter: keeperCoreMainAssembly.formattersAssembly.amountFormatter,
            signedAmountFormatter: keeperCoreMainAssembly.formattersAssembly.signedAmountFormatter,
            currencyProvider: { keeperCoreMainAssembly.storesAssembly.currencyStore.state }
        )
        let homeBannersViewModel = WalletBalanceHomeBannersViewModel(
            homeBannersStore: keeperCoreMainAssembly.storesAssembly.homeBannersStore,
            deeplinkParser: DeeplinkParser(),
            analyticsProvider: coreAssembly.analyticsProvider
        )

        let viewModel = WalletBalanceViewModelImplementation(
            balanceListModel: WalletBalanceBalanceModel(
                walletsStore: keeperCoreMainAssembly.storesAssembly.walletsStore,
                balanceStore: keeperCoreMainAssembly.storesAssembly.managedBalanceStore,
                stackingPoolsStore: keeperCoreMainAssembly.storesAssembly.stackingPoolsStore,
                appSettingsStore: keeperCoreMainAssembly.storesAssembly.appSettingsStore,
                configuration: keeperCoreMainAssembly.configurationAssembly.configuration
            ),
            balanceLoader: keeperCoreMainAssembly.loadersAssembly.balanceLoader,
            setupModel: WalletBalanceSetupModel(
                walletsStore: keeperCoreMainAssembly.storesAssembly.walletsStore,
                securityStore: keeperCoreMainAssembly.storesAssembly.securityStore,
                walletNotificationStore: keeperCoreMainAssembly.storesAssembly.walletNotificationStore,
                mnemonicsAccess: keeperCoreMainAssembly.secureAssembly.mnemonicAccess,
                configuration: keeperCoreMainAssembly.configurationAssembly.configuration
            ),
            totalBalanceModel: WalletTotalBalanceModel(
                walletsStore: keeperCoreMainAssembly.storesAssembly.walletsStore,
                totalBalanceStore: keeperCoreMainAssembly.storesAssembly.totalBalanceStore,
                appSettingsStore: keeperCoreMainAssembly.storesAssembly.appSettingsStore,
                backgroundUpdate: keeperCoreMainAssembly.backgroundUpdateAssembly.backgroundUpdate,
                balanceLoader: keeperCoreMainAssembly.loadersAssembly.balanceLoader,
                updateQueue: queue
            ),
            walletsStore: keeperCoreMainAssembly.storesAssembly.walletsStore,
            notificationStore: keeperCoreMainAssembly.storesAssembly.internalNotificationsStore,
            configuration: keeperCoreMainAssembly.configurationAssembly.configuration,
            appSettingsStore: keeperCoreMainAssembly.storesAssembly.appSettingsStore,
            listMapper:
            WalletBalanceListMapper(
                stakingMapper: stakingMappper,
                amountFormatter: keeperCoreMainAssembly.formattersAssembly.amountFormatter,
                balanceItemMapper: balanceItemMapper,
                rateConverter: RateConverter(),
                tonStakingAPYProvider: { [keeperCoreMainAssembly] wallet in
                    let configuration = keeperCoreMainAssembly.configurationAssembly.configuration
                    guard !configuration.flag(\.stakingDisabled, network: wallet.network) else {
                        return nil
                    }

                    return keeperCoreMainAssembly.storesAssembly.stackingPoolsStore.state[wallet]?
                        .filter { configuration.value(\.stakingEnabledProviders).contains($0.implementation.type.rawValue) }
                        .map(\.apy)
                        .max()
                },
                tonStakingAPYTextFormatter: { value in
                    tradeAssetDetailsValueFormatter.earnApyValueFormatter(value)
                }
            ),
            headerMapper: WalletBalanceHeaderMapper(
                amountFormatter: keeperCoreMainAssembly.formattersAssembly.amountFormatter,
                dateFormatter: keeperCoreMainAssembly.formattersAssembly.dateFormatter
            ),
            urlOpener: coreAssembly.urlOpener(),
            appSettings: coreAssembly.appSettings,
            tooltipsService: coreAssembly.tooltipsAssembly.service,
            homeBannersViewModel: homeBannersViewModel
        )
        viewModel.bindBannersSectionVisibility()
        homeBannersViewModel.onOpenLink = { url in
            coreAssembly.urlOpener().open(url: url)
        }
        let viewController = WalletBalanceViewController(
            viewModel: viewModel,
            tooltipsService: coreAssembly.tooltipsAssembly.service
        )
        return .init(view: viewController, output: viewModel, input: viewModel)
    }
}
