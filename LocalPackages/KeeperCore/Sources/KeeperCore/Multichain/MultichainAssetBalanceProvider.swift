import BigInt
import Foundation

public struct MultichainAssetBalanceProvider {
    private let balanceService: MultichainService
    private let currencyStore: CurrencyStore
    private let cache = Cache()

    public init(
        balanceService: MultichainService,
        currencyStore: CurrencyStore
    ) {
        self.balanceService = balanceService
        self.currencyStore = currencyStore
    }

    public func cachedAsset(for assetId: String, wallet: Wallet) -> MultichainAsset? {
        return cache.asset(for: .init(walletId: wallet.id, assetId: assetId))
    }

    public func loadAsset(for assetId: String, wallet: Wallet) async -> MultichainAsset? {
        let currency = currencyStore.state

        do {
            let assets = try await balanceService.getWalletAssets(
                walletId: wallet.id,
                currencies: requestedCurrencyCodes(for: currency),
                chain: nil,
                search: nil,
                availableOnly: nil,
                showHidden: nil,
                limit: nil,
                cursor: nil
            ).assets

            guard let asset = assets.first(where: { $0.asset.assetId == assetId }) else {
                return cachedAsset(for: assetId, wallet: wallet)
            }

            cache.store(asset, for: .init(walletId: wallet.id, assetId: assetId))
            return asset
        } catch {
            return cachedAsset(for: assetId, wallet: wallet)
        }
    }
}

private extension MultichainAssetBalanceProvider {
    func requestedCurrencyCodes(for currency: Currency) -> [String] {
        var codes = [currency.code.lowercased()]
        if currency != .defaultCurrency {
            codes.append(Currency.defaultCurrency.code.lowercased())
        }
        return codes
    }
}

private final class Cache {
    private var assets: [Key: MultichainAsset] = [:]
    private let lock = NSLock()

    func asset(for key: Key) -> MultichainAsset? {
        lock.lock()
        defer { lock.unlock() }
        return assets[key]
    }

    func store(_ asset: MultichainAsset, for key: Key) {
        lock.lock()
        defer { lock.unlock() }
        assets[key] = asset
    }
}

private struct Key: Hashable {
    let walletId: String
    let assetId: String
}
