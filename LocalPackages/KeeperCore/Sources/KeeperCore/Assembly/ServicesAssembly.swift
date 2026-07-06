import Foundation

public final class ServicesAssembly {
    private let repositoriesAssembly: RepositoriesAssembly
    private let storesAssembly: StoresAssembly
    private let apiAssembly: APIAssembly
    private let tonkeeperAPIAssembly: TonkeeperAPIAssembly
    private let scamAPIAssembly: ScamAPIAssembly
    private let coreAssembly: CoreAssembly
    private let secureAssembly: SecureAssembly
    private let batteryAssembly: BatteryAssembly
    private let tronUSDTAssembly: TronUSDTAssembly
    private let configurationAssembly: ConfigurationAssembly
    private let nativeSwapAPIAssembly: NativeSwapAPIAssembly
    private let currenciesAPIAssembly: CurrenciesAPIAssembly
    private let onRampAPIAssembly: OnRampAPIAssembly
    private let multichainAPIAssembly: MultichainAPIAssembly
    private let tradingAssembly: TradingAssembly
    private let firebaseUserIdProvider: () -> String?

    init(
        repositoriesAssembly: RepositoriesAssembly,
        storesAssembly: StoresAssembly,
        apiAssembly: APIAssembly,
        tonkeeperAPIAssembly: TonkeeperAPIAssembly,
        scamAPIAssembly: ScamAPIAssembly,
        coreAssembly: CoreAssembly,
        secureAssembly: SecureAssembly,
        batteryAssembly: BatteryAssembly,
        tronUSDTAssembly: TronUSDTAssembly,
        configurationAssembly: ConfigurationAssembly,
        nativeSwapAPIAssembly: NativeSwapAPIAssembly,
        currenciesAPIAssembly: CurrenciesAPIAssembly,
        onRampAPIAssembly: OnRampAPIAssembly,
        multichainAPIAssembly: MultichainAPIAssembly,
        tradingAssembly: TradingAssembly,
        firebaseUserIdProvider: @escaping () -> String?
    ) {
        self.repositoriesAssembly = repositoriesAssembly
        self.storesAssembly = storesAssembly
        self.apiAssembly = apiAssembly
        self.tonkeeperAPIAssembly = tonkeeperAPIAssembly
        self.scamAPIAssembly = scamAPIAssembly
        self.coreAssembly = coreAssembly
        self.secureAssembly = secureAssembly
        self.batteryAssembly = batteryAssembly
        self.tronUSDTAssembly = tronUSDTAssembly
        self.configurationAssembly = configurationAssembly
        self.nativeSwapAPIAssembly = nativeSwapAPIAssembly
        self.currenciesAPIAssembly = currenciesAPIAssembly
        self.onRampAPIAssembly = onRampAPIAssembly
        self.multichainAPIAssembly = multichainAPIAssembly
        self.tradingAssembly = tradingAssembly
        self.firebaseUserIdProvider = firebaseUserIdProvider
    }

    public func walletsService() -> WalletsService {
        WalletsServiceImplementation(keeperInfoRepository: repositoriesAssembly.keeperInfoRepository())
    }

    public func walletsResolveService() -> WalletsResolveService {
        WalletsResolveServiceImplementation(
            apiProvider: apiAssembly.apiProvider,
            firebaseUserIdProvider: firebaseUserIdProvider
        )
    }

    public func balanceService() -> BalanceService {
        BalanceServiceImplementation(
            tonBalanceService: tonBalanceService(),
            jettonsBalanceService: jettonsBalanceService(),
            tronBalanceService: tronUSDTAssembly.balanceService(),
            batteryService: batteryAssembly.batteryService(),
            stackingService: stackingService(),
            tonProofTokenService: tonProofTokenService(),
            walletBalanceRepository: repositoriesAssembly.walletBalanceRepository()
        )
    }

    func tonBalanceService() -> TonBalanceService {
        TonBalanceServiceImplementation(apiProvider: apiAssembly.apiProvider)
    }

    func tronBalanceService() -> TronBalanceService {
        tronUSDTAssembly.balanceService()
    }

    public func tronUsdtApi() -> TronUSDTAPI {
        tronUSDTAssembly.tronUsdtApi
    }

    func accountService() -> AccountService {
        AccountServiceImplementation(apiProvider: apiAssembly.apiProvider)
    }

    public func jettonService() -> JettonService {
        JettonServiceImplementation(apiProvider: apiAssembly.apiProvider)
    }

    func jettonsBalanceService() -> JettonBalanceService {
        JettonBalanceServiceImplementation(apiProvider: apiAssembly.apiProvider)
    }

    public func stackingService() -> StakingService {
        StakingServiceImplementation(
            apiProvider: apiAssembly.apiProvider
        )
    }

    func activeWalletsService() -> ActiveWalletsService {
        ActiveWalletsServiceImplementation(
            apiProvider: apiAssembly.apiProvider,
            jettonsBalanceService: jettonsBalanceService(),
            accountNFTService: accountNftService(),
            walletsService: walletsService()
        )
    }

    public func ratesService() -> RatesService {
        RatesServiceImplementation(
            api: apiAssembly.api,
            ratesRepository: repositoriesAssembly.ratesRepository()
        )
    }

    func currencyService() -> CurrencyService {
        CurrencyServiceImplementation(
            keeperInfoRepository: repositoriesAssembly.keeperInfoRepository()
        )
    }

    public func historyService() -> HistoryService {
        HistoryServiceImplementation(
            apiProvider: apiAssembly.apiProvider,
            repository: repositoriesAssembly.historyRepository(),
            cacheNamespace: .allEvents,
            tronBip39ImportFixEnabled: configurationAssembly
                .configuration
                .featureEnabled(.tronBip39ImportFix)
        )
    }

    public func tronUSDTHistoryService() -> HistoryService {
        HistoryServiceImplementation(
            apiProvider: apiAssembly.apiProvider,
            repository: repositoriesAssembly.historyRepository(),
            cacheNamespace: .tronUSDT,
            tronBip39ImportFixEnabled: configurationAssembly
                .configuration
                .featureEnabled(.tronBip39ImportFix)
        )
    }

    public func walletService() -> WalletService {
        WalletServiceImplementation(apiProvider: apiAssembly.apiProvider)
    }

    public func nftService() -> NFTService {
        NFTServiceImplementation(
            apiProvider: apiAssembly.apiProvider,
            scamAPI: scamAPIAssembly.api,
            nftRepository: repositoriesAssembly.nftRepository()
        )
    }

    public func blockchainService() -> BlockchainService {
        BlockchainServiceImplementation(
            apiProvider: apiAssembly.apiProvider
        )
    }

    public func accountNftService() -> AccountNFTService {
        AccountNFTServiceImplementation(
            apiProvider: apiAssembly.apiProvider,
            accountNFTRepository: repositoriesAssembly.accountsNftRepository(),
            nftRepository: repositoriesAssembly.nftRepository()
        )
    }

    func chartService() -> ChartService {
        ChartServiceImplementation(
            apiProvider: apiAssembly.apiProvider,
            repository: repositoriesAssembly.chartDataRepository()
        )
    }

    public func sendService() -> SendService {
        SendServiceImplementation(apiProvider: apiAssembly.apiProvider)
    }

    public func dnsService() -> DNSService {
        DNSServiceImplementation(apiProvider: apiAssembly.apiProvider)
    }

    public func dappFetchService() -> DappFetchService {
        DappFetchServiceImplementation(apiProvider: apiAssembly.apiProvider)
    }

    public func popularAppsService() -> PopularAppsService {
        PopularAppsServiceImplementation(
            api: tonkeeperAPIAssembly.api,
            popularAppsRepository: repositoriesAssembly.popularAppsRepository()
        )
    }

    public func encryptedCommentService() -> EncryptedCommentService {
        EncryptedCommentServiceImplementation(
            mnemonicAccess: secureAssembly.mnemonicAccess
        )
    }

    public func searchEngineService() -> SearchEngineServiceProtocol {
        SearchEngineService(session: .shared)
    }

    public func tonProofTokenService() -> TonProofTokenService {
        TonProofTokenServiceImplementation(
            keeperInfoRepository: repositoriesAssembly.keeperInfoRepository(),
            tonProofTokenRepository: repositoriesAssembly.tonProofTokenRepository(),
            api: apiAssembly.api
        )
    }

    public func notificationsService(
        walletNotificationsStore: WalletNotificationStore,
        tonConnectAppsStore: TonConnectAppsStore
    ) -> NotificationsService {
        NotificationsServiceImplementation(
            pushNotificationAPI: apiAssembly.pushNotificationsAPI,
            walletNotificationsStore: walletNotificationsStore,
            tonConnectAppsStore: tonConnectAppsStore,
            tonProofTokenService: tonProofTokenService()
        )
    }

    public func cookiesService() -> CookiesService {
        CookiesServiceImplementation(cookiesRepository: repositoriesAssembly.cookiesRepository())
    }

    public func nativeSwapService() -> NativeSwapService {
        NativeSwapServiceImplementation(nativeSwapAPI: nativeSwapAPIAssembly.nativeSwapAPI())
    }

    public func currenciesService() -> CurrenciesService {
        CurrenciesServiceImplementation(
            api: currenciesAPIAssembly.api,
            repository: repositoriesAssembly.currenciesRepository()
        )
    }

    public func onRampService() -> OnRampService {
        OnRampServiceImplementation(
            onRampAPI: onRampAPIAssembly.onRampAPI(),
            repository: repositoriesAssembly.onRampRepository()
        )
    }

    public func multichainService() -> MultichainService {
        MultichainServiceImplementation(
            multichainClientAPI: multichainAPIAssembly.multichainAPI()
        )
    }

    public func tradingShelvesService() -> TradingShelvesService {
        tradingAssembly.shelvesService
    }

    public func assetsListService() -> TradingAssetsListService {
        tradingAssembly.assetsListService
    }

    public func assetDetailsService() -> TradingAssetDetailsService {
        tradingAssembly.assetDetailsService
    }

    public private(set) lazy var tronUSDTFeesService: TronUsdtFeesService = TronUSDTFeesServiceImplementation(
        tronUsdtApi: tronUSDTAssembly.tronUsdtApi,
        walletsStore: storesAssembly.walletsStore,
        batteryCalculation: batteryAssembly.batteryCalculation,
        configuration: configurationAssembly.configuration
    )
}
