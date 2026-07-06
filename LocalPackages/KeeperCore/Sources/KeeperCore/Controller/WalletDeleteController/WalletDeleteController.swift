import Foundation
import TKLogging

public final class WalletDeleteController {
    private let walletStore: WalletsStore
    private let keeperInfoStore: KeeperInfoStore
    private let mnemonicAccess: MnemonicAccess

    init(
        walletStore: WalletsStore,
        keeperInfoStore: KeeperInfoStore,
        mnemonicAccess: MnemonicAccess
    ) {
        self.walletStore = walletStore
        self.keeperInfoStore = keeperInfoStore
        self.mnemonicAccess = mnemonicAccess
    }

    public func deleteWallet(wallet: Wallet, passcode: String) async {
        await walletStore.deleteWallet(wallet)
        do {
            try await mnemonicAccess.deleteMnemonic(wallet: wallet, passcode: passcode)
        } catch {
            #if DEBUG
                Log.e("🪵 mnemonic data is not deleted due to error: \(error)")
            #endif
        }
    }

    public func deleteWallet(wallet: Wallet) async {
        await walletStore.deleteWallet(wallet)
    }

    public func deleteAll(passcode: String? = nil) async {
        await walletStore.deleteAllWallets()
        do {
            try await mnemonicAccess.deleteAll(passcode: passcode)
        } catch {
            #if DEBUG
                Log.e("🪵 mnemonic data is not deleted due to error: \(error)")
            #endif
        }
    }
}
