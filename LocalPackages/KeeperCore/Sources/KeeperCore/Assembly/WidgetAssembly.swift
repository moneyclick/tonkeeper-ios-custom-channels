import Foundation

public final class WidgetAssembly {
    private let repositoriesAssembly: RepositoriesAssembly
    private let servicesAssembly: ServicesAssembly
    private let storesAssembly: StoresAssembly
    private let coreAssembly: CoreAssembly
    private let formattersAssembly: FormattersAssembly
    private let walletsUpdateAssembly: WalletsUpdateAssembly
    private let configurationAssembly: ConfigurationAssembly
    private let apiAssembly: APIAssembly
    private let loadersAssembly: LoadersAssembly

    init(
        repositoriesAssembly: RepositoriesAssembly,
        coreAssembly: CoreAssembly,
        servicesAssembly: ServicesAssembly,
        storesAssembly: StoresAssembly,
        formattersAssembly: FormattersAssembly,
        walletsUpdateAssembly: WalletsUpdateAssembly,
        configurationAssembly: ConfigurationAssembly,
        apiAssembly: APIAssembly,
        loadersAssembly: LoadersAssembly
    ) {
        self.repositoriesAssembly = repositoriesAssembly
        self.coreAssembly = coreAssembly
        self.servicesAssembly = servicesAssembly
        self.storesAssembly = storesAssembly
        self.formattersAssembly = formattersAssembly
        self.walletsUpdateAssembly = walletsUpdateAssembly
        self.configurationAssembly = configurationAssembly
        self.apiAssembly = apiAssembly
        self.loadersAssembly = loadersAssembly
    }

    public var walletsService: WalletsService {
        servicesAssembly.walletsService()
    }

    public func balanceWidgetController() -> BalanceWidgetController {
        BalanceWidgetController(
            walletService: servicesAssembly.walletsService(),
            balanceService: servicesAssembly.balanceService(),
            ratesService: servicesAssembly.ratesService(),
            amountFormatter: formattersAssembly.amountFormatter
        )
    }

    public func chartV2Controller(token: Token) -> ChartV2Controller {
        chartV2Controller(chartIdentifier: token.chartIdentifier)
    }

    public func chartV2Controller(chartIdentifier: String) -> ChartV2Controller {
        ChartV2Controller(
            chartIdentifier: chartIdentifier,
            chartService: widgetChartService(),
            currencyStore: storesAssembly.currencyStore,
            walletsService: servicesAssembly.walletsService()
        )
    }
}

private extension WidgetAssembly {
    func widgetChartService() -> ChartService {
        ChartServiceImplementation(
            apiProvider: apiAssembly.apiProvider,
            repository: repositoriesAssembly.persistentChartDataRepository()
        )
    }
}
