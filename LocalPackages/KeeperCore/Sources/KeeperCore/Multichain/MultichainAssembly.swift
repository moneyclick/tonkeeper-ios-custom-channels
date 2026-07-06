public final class MultichainAssembly {
    public private(set) lazy var multichainAssetBalanceProvider: MultichainAssetBalanceProvider = MultichainAssetBalanceProvider(
        balanceService: multichainService,
        currencyStore: currencyStore
    )

    private let appInfoProvider: AppInfoProvider
    private let mnemonicAccess: MnemonicAccess
    private let walletsStore: WalletsStore
    private let multichainService: MultichainService
    private let currencyStore: CurrencyStore

    init(
        appInfoProvider: AppInfoProvider,
        mnemonicAccess: MnemonicAccess,
        walletsStore: WalletsStore,
        multichainService: MultichainService,
        currencyStore: CurrencyStore
    ) {
        self.appInfoProvider = appInfoProvider
        self.mnemonicAccess = mnemonicAccess
        self.walletsStore = walletsStore
        self.multichainService = multichainService
        self.currencyStore = currencyStore
    }
}
