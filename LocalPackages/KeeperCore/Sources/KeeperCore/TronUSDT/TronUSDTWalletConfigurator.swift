import Foundation
import TronSwift

public struct TronWalletConfigurator {
    public enum Error: Swift.Error {
        case cancelled
    }

    private let walletsStore: WalletsStore
    private let mnemonicAccess: MnemonicAccess
    private let configurationAssembly: ConfigurationAssembly

    init(
        walletsStore: WalletsStore,
        mnemonicAccess: MnemonicAccess,
        configurationAssembly: ConfigurationAssembly
    ) {
        self.walletsStore = walletsStore
        self.mnemonicAccess = mnemonicAccess
        self.configurationAssembly = configurationAssembly
    }

    public func turnOn(wallet: Wallet, passcodeProvider: () async -> String?) async throws {
        if let tron = wallet.tron {
            let updatedTron = WalletTron(
                publicKey: tron.publicKey,
                address: tron.address,
                isOn: true
            )
            await walletsStore.setWalletTron(wallet: wallet, tron: updatedTron)
        } else if let passcode = await passcodeProvider() {
            let mnemonic = try await mnemonicAccess.getMnemonic(wallet: wallet, passcode: passcode)
            let tronKeyPair = try TonTron.derivedKeyPair(
                tonMnemonic: mnemonic.mnemonicWords,
                index: 0,
                useBip39DerivationForBip39Mnemonics: configurationAssembly
                    .configuration
                    .featureEnabled(.tronBip39ImportFix)
            )
            let tron = try WalletTron(
                publicKey: tronKeyPair.publicKey,
                address: TronSwift.Address(publicKey: tronKeyPair.publicKey),
                isOn: true
            )
            await walletsStore.setWalletTron(wallet: wallet, tron: tron)
        } else {
            throw Error.cancelled
        }
    }

    public func turnOff(wallet: Wallet) async {
        guard let tron = wallet.tron else { return }
        let updatedTron = WalletTron(
            publicKey: tron.publicKey,
            address: tron.address,
            isOn: false
        )
        await walletsStore.setWalletTron(wallet: wallet, tron: updatedTron)
    }
}
