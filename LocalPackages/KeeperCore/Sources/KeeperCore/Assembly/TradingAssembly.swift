import Foundation

public final class TradingAssembly {
    private let tradingAPIAssembly: TradingAPIAssembly
    private let appInfoProvider: AppInfoProvider
    private let repositoriesAssembly: RepositoriesAssembly

    init(
        tradingAPIAssembly: TradingAPIAssembly,
        appInfoProvider: AppInfoProvider,
        repositoriesAssembly: RepositoriesAssembly
    ) {
        self.tradingAPIAssembly = tradingAPIAssembly
        self.appInfoProvider = appInfoProvider
        self.repositoriesAssembly = repositoriesAssembly
    }

    private(set) lazy var shelvesService: TradingShelvesService = TradingShelvesServiceImplementation(
        api: tradingAPIAssembly.api,
        repository: tradingShelvesRepository,
        requestContextProvider: requestContextProvider
    )

    private(set) lazy var assetsListService: TradingAssetsListService = TradingAssetsListServiceImplementation(
        api: tradingAPIAssembly.api,
        repository: assetsListRepository,
        requestContextProvider: requestContextProvider
    )

    private(set) lazy var assetDetailsService: TradingAssetDetailsService = TradingAssetDetailsServiceImplementation(
        api: tradingAPIAssembly.api,
        repository: assetDetailsRepository,
        requestContextProvider: requestContextProvider
    )

    private lazy var tradingShelvesRepository: TradingShelvesRepository = TradingShelvesRepositoryImplementation()

    private lazy var assetsListRepository: TradingAssetsListRepository = TradingAssetsListRepositoryImplementation()

    private lazy var assetDetailsRepository: TradingAssetDetailsRepository = TradingAssetDetailsRepositoryImplementation()

    private lazy var requestContextProvider: TradingRequestContextProvider =
        TradingRequestContextProviderImplementation(
            appInfoProvider: appInfoProvider,
            keeperInfoRepository: repositoriesAssembly.keeperInfoRepository()
        )
}
