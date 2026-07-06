import Foundation
import TKLogging
import TONWalletKit

public final actor TONWalletKitWalletsSynchronizer {
    private let tonWalletKit: TONWalletKit
    private let walletsStore: WalletsStore

    init(tonWalletKit: TONWalletKit, walletsStore: WalletsStore) {
        self.tonWalletKit = tonWalletKit
        self.walletsStore = walletsStore
    }

    public func syncWallets() async {
        let wallets = walletsStore.wallets
        guard !wallets.isEmpty else { return }

        await addWallets(wallets)
    }

    public func startAutoSync() {
        walletsStore.addObserver(self) { [weak self] _, event in
            switch event {
            case let .didAddWallets(wallets):
                Task {
                    await self?.addWallets(wallets)
                }
            case let .didDeleteWallet(wallet):
                Task {
                    await self?.removeWallet(wallet)
                }
            case .didDeleteAll:
                Task {
                    await self?.removeAllWallets()
                }
            default:
                break
            }
        }
    }

    private func addWallets(_ wallets: [Wallet]) async {
        for wallet in wallets {
            await addWallet(wallet)
        }
    }

    private func addWallet(_ wallet: Wallet) async {
        let adapter = TONWalletAdapter(tonWallet: wallet)
        // `wallet(id:)` throws when the wallet is missing; treat any throw as "not present" and proceed to add.
        let existingWallet = try? await tonWalletKit.wallet(id: adapter.identifier())

        guard existingWallet == nil else {
            return
        }

        do {
            _ = try await tonWalletKit.add(walletAdapter: adapter)
        } catch {
            Log.e(
                "\(String(reflecting: Self.self)): failed to add wallet to TONWalletKit",
                extraInfo: [
                    "error": error.localizedDescription,
                    "walletId": wallet.id,
                ]
            )
        }
    }

    private func removeWallet(_ wallet: Wallet) async {
        let adapter = TONWalletAdapter(tonWallet: wallet)

        do {
            try await tonWalletKit.remove(walletId: adapter.identifier())
        } catch {
            Log.e(
                "\(String(reflecting: Self.self)): failed to remove wallet from TONWalletKit",
                extraInfo: [
                    "error": error.localizedDescription,
                    "walletId": wallet.id,
                ]
            )
        }
    }

    private func removeAllWallets() async {
        do {
            let wallets = try await tonWalletKit.wallets()

            for wallet in wallets {
                do {
                    try await tonWalletKit.remove(walletId: wallet.id)
                } catch {
                    Log.e(
                        "\(String(reflecting: Self.self)): failed to remove wallet during removeAllWallets",
                        extraInfo: [
                            "error": error.localizedDescription,
                            "walletId": wallet.id,
                        ]
                    )
                }
            }
        } catch {
            Log.e(
                "\(String(reflecting: Self.self)): failed to fetch wallets for removeAllWallets",
                extraInfo: [
                    "error": error.localizedDescription,
                ]
            )
        }
    }
}
