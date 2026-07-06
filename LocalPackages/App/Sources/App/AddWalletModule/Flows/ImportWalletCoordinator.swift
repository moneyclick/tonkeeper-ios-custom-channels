import KeeperCore
import KeeperCoreComponents
import KeeperCoreSensitive
import TKCoordinator
import TKCore
import TKLocalize
import TKLogging
import TKScreenKit
import TKUIKit
import UIKit

final class ImportWalletCoordinator: RouterCoordinator<NavigationControllerRouter> {
    var didCancel: (() -> Void)?
    var didImportWallets: (() -> Void)?

    private let network: Network
    private let analyticsProvider: AnalyticsProvider
    private let walletsUpdateAssembly: WalletsUpdateAssembly
    private let storesAssembly: StoresAssembly
    private let configurationAssembly: ConfigurationAssembly
    private let checkImportedWalletsForAnalytics: (CoreMnemonic, [WalletContractVersion]) async -> Void
    private let hasPasscodeChecker: HasPasscodeChecker
    private let customizeWalletModule: () -> MVVMModule<UIViewController, CustomizeWalletModuleOutput, Void>

    init(
        router: NavigationControllerRouter,
        analyticsProvider: AnalyticsProvider,
        walletsUpdateAssembly: WalletsUpdateAssembly,
        storesAssembly: StoresAssembly,
        hasPasscodeChecker: HasPasscodeChecker,
        configurationAssembly: ConfigurationAssembly,
        network: Network,
        checkImportedWalletsForAnalytics: @escaping (CoreMnemonic, [WalletContractVersion]) async -> Void,
        customizeWalletModule: @escaping () -> MVVMModule<UIViewController, CustomizeWalletModuleOutput, Void>
    ) {
        self.analyticsProvider = analyticsProvider
        self.walletsUpdateAssembly = walletsUpdateAssembly
        self.storesAssembly = storesAssembly
        self.configurationAssembly = configurationAssembly
        self.network = network
        self.checkImportedWalletsForAnalytics = checkImportedWalletsForAnalytics
        self.customizeWalletModule = customizeWalletModule
        self.hasPasscodeChecker = hasPasscodeChecker
        super.init(router: router)
    }

    override func start() {
        openRecoveryPhraseInput()
    }
}

private extension ImportWalletCoordinator {
    func openRecoveryPhraseInput() {
        let inputRecoveryPhrase = TKInputRecoveryPhraseAssembly.module(
            title: TKLocales.ImportWallet.title,
            caption: TKLocales.ImportWallet.description,
            set12WordsButtonTitle: TKLocales.ImportWallet.set12Words,
            set24WordsButtonTitle: TKLocales.ImportWallet.set24Words,
            continueButtonTitle: TKLocales.Actions.continueAction,
            pasteButtonTitle: TKLocales.Actions.paste,
            validator: AddWalletInputRecoveryPhraseValidator(),
            suggestsProvider: AddWalletInputRecoveryPhraseSuggestsProvider()
        )

        inputRecoveryPhrase.output.didInputRecoveryPhrase = { [weak self] phrase, completion in
            guard let self = self else { return }
            let derivationType: DerivationType = .guessByWords(phrase)
            if case .unknown = derivationType {
                /* TODO: ask the design team what message to show */
                return
            }
            let coreMnemonic = CoreMnemonic(
                mnemonicWords: phrase,
                type: derivationType
            )
            self.detectActiveWallets(mnemonic: coreMnemonic, completion: completion)
            self.resolveWallets(mnemonic: coreMnemonic)
        }

        if router.rootViewController.viewControllers.isEmpty {
            inputRecoveryPhrase.viewController.setupLeftCloseButton { [weak self] in
                self?.didCancel?()
            }
        } else {
            inputRecoveryPhrase.viewController.setupBackButton()
        }

        router.push(
            viewController: inputRecoveryPhrase.viewController,
            animated: true,
            onPopClosures: { [weak self] in
                self?.didCancel?()
            },
            completion: nil
        )
    }

    func detectActiveWallets(mnemonic: CoreMnemonic, completion: @escaping () -> Void) {
        Task {
            do {
                let activeWallets = try await walletsUpdateAssembly.walletImportController().findActiveWallets(
                    mnemonic: mnemonic,
                    network: network,
                    checkHistory: configurationAssembly.configuration.featureEnabled(.mnemonicsStorageV2)
                )
                await MainActor.run {
                    completion()
                    handleActiveWallets(mnemonic: mnemonic, activeWalletModels: activeWallets)
                }
            } catch {
                Log.w("\(error)")
                await MainActor.run {
                    completion()
                }
            }
        }
    }

    func resolveWallets(mnemonic: CoreMnemonic) {
        guard network == .mainnet else {
            return
        }

        let walletStoreState = walletsUpdateAssembly.storesAssembly.walletsStore.getState()

        // skip for onboarding flow
        if case .empty = walletStoreState {
            return
        }

        guard let keyPair = try? mnemonic.toKeyPair() else {
            return
        }

        let walletsResolveService = walletsUpdateAssembly.servicesAssembly.walletsResolveService()
        walletsResolveService.resolveWallets(by: keyPair.publicKey)
    }

    func handleActiveWallets(mnemonic: CoreMnemonic, activeWalletModels: [ActiveWalletModel]) {
        let shouldAcceptWallet: (ActiveWalletModel) -> Bool = { wallet in
            switch mnemonic.type {
            case .bip39soft, .unknown:
                return wallet.history != .empty
            case .bip39, .ton:
                return true
            }
        }
        let activeWalletModels = activeWalletModels.filter(shouldAcceptWallet)
        guard !activeWalletModels.isEmpty else {
            ToastPresenter.showToast(
                configuration: .defaultConfiguration(text: TKLocales.ImportWallet.incorrectPhrase)
            )
            return
        }
        if activeWalletModels.count == 1, activeWalletModels[0].revision == WalletContractVersion.currentVersion {
            handleDidChooseRevisions(mnemonic: mnemonic, revisions: [WalletContractVersion.currentVersion])
        } else {
            openChooseWalletToAdd(mnemonic: mnemonic, activeWalletModels: activeWalletModels)
        }
    }

    func openChooseWalletToAdd(mnemonic: CoreMnemonic, activeWalletModels: [ActiveWalletModel]) {
        let module = ChooseWalletToAddAssembly.module(
            activeWalletModels: activeWalletModels,
            configuration: ChooseWalletToAddConfiguration(
                showRevision: true,
                selectLastRevision: true
            ),
            amountFormatter: walletsUpdateAssembly.formattersAssembly.amountFormatter,
            network: network
        )

        module.output.didSelectWallets = { [weak self] wallets in
            let revisions = wallets.map { $0.revision }
            self?.handleDidChooseRevisions(mnemonic: mnemonic, revisions: revisions)
        }

        module.view.setupBackButton()

        router.push(
            viewController: module.view,
            animated: true,
            onPopClosures: {},
            completion: nil
        )
    }

    func handleDidChooseRevisions(mnemonic: CoreMnemonic, revisions: [WalletContractVersion]) {
        if hasPasscodeChecker.hasPasscode {
            openConfirmPasscode(mnemonic: mnemonic, revisions: revisions)
        } else {
            openCreatePasscode(mnemonic: mnemonic, revisions: revisions)
        }
    }

    func openCreatePasscode(mnemonic: CoreMnemonic, revisions: [WalletContractVersion]) {
        let coordinator = PasscodeCreateCoordinator(
            router: router
        )

        coordinator.didCancel = { [weak self, weak coordinator] in
            self?.removeChild(coordinator)
            self?.router.dismiss(animated: true, completion: {
                self?.didCancel?()
            })
        }

        coordinator.didCreatePasscode = { [weak self] passcode in
            self?.openCustomizeWallet(
                mnemonic: mnemonic,
                revisions: revisions,
                passcode: passcode,
                animated: true
            )
        }

        addChild(coordinator)
        coordinator.start()
    }

    func openConfirmPasscode(mnemonic: CoreMnemonic, revisions: [WalletContractVersion]) {
        PasscodeInputCoordinator.present(
            parentCoordinator: self,
            parentRouter: self.router,
            mnemonicAccess: walletsUpdateAssembly.secureAssembly.mnemonicAccess,
            securityStore: storesAssembly.securityStore,
            onCancel: {},
            onInput: { [weak self] passcode in
                self?.openCustomizeWallet(
                    mnemonic: mnemonic,
                    revisions: revisions,
                    passcode: passcode,
                    animated: true
                )
            }
        )
    }

    func openCustomizeWallet(
        mnemonic: CoreMnemonic,
        revisions: [WalletContractVersion],
        passcode: String,
        animated: Bool
    ) {
        let module = customizeWalletModule()

        module.output.didCustomizeWallet = { [weak self] model in
            guard let self else { return }
            Task {
                do {
                    try await self.importWallet(
                        mnemonic: mnemonic,
                        revisions: revisions,
                        model: model,
                        passcode: passcode
                    )
                    Task {
                        await self.checkImportedWalletsForAnalytics(
                            mnemonic,
                            revisions
                        )
                    }
                    await MainActor.run {
                        self.didImportWallets?()
                    }
                } catch {
                    Log.e("Log: Wallet import failed", extraInfo: [
                        "error": error.localizedDescription,
                    ])
                }
            }
        }

        module.view.setupBackButton()
        router.push(viewController: module.view, animated: animated)
    }

    func importWallet(
        mnemonic: CoreMnemonic,
        revisions: [WalletContractVersion],
        model: CustomizeWalletModel,
        passcode: String
    ) async throws {
        self.analyticsProvider.log(eventKey: .importWallet)

        let addController = walletsUpdateAssembly.walletAddController()
        let metaData = WalletMetaData(
            label: model.name,
            tintColor: model.tintColor,
            icon: model.icon
        )
        try await addController.importWallets(
            mnemonic: mnemonic,
            revisions: revisions,
            metaData: metaData,
            passcode: passcode,
            network: network
        )
    }
}
