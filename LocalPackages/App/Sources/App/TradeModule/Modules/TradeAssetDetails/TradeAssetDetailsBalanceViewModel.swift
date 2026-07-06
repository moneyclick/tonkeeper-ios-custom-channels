import BigInt
import Combine
import Foundation
import KeeperCore
import TronSwift

struct TradeAssetDetailsBalanceSnapshot {
    let symbol: String
    let imageURL: URL?
    let amount: BigUInt
    let fractionDigits: Int
    let convertedAmount: Decimal?
    let tagText: String?
}

@MainActor
final class TradeAssetDetailsBalanceViewModel: ObservableObject {
    @Published private(set) var state: TradeAssetDetailsBalanceSnapshot?

    private let wallet: Wallet?
    private let typedAssetId: TradingAssetToken?
    private let balanceLoader: BalanceLoader
    private let convertedBalanceStore: ConvertedBalanceStore

    init(
        wallet: Wallet?,
        typedAssetId: TradingAssetToken?,
        balanceLoader: BalanceLoader,
        convertedBalanceStore: ConvertedBalanceStore
    ) {
        self.wallet = wallet
        self.typedAssetId = typedAssetId
        self.balanceLoader = balanceLoader
        self.convertedBalanceStore = convertedBalanceStore

        convertedBalanceStore.addObserver(self) { observer, event in
            switch event {
            case let .didUpdateConvertedBalance(wallet):
                Task { @MainActor in
                    observer.handleBalanceUpdate(wallet: wallet)
                }
            }
        }
    }

    func scheduleUpdate() {
        primeCache()
        reload()
    }
}

private extension TradeAssetDetailsBalanceViewModel {
    func handleBalanceUpdate(wallet: Wallet) {
        guard wallet == self.wallet else {
            return
        }
        state = storeSnapshot()
    }

    func primeCache() {
        guard let cached = storeSnapshot() else {
            return
        }
        state = cached
    }

    func reload() {
        guard let wallet else {
            return
        }
        balanceLoader.loadWalletBalance(wallet: wallet)
    }
}

private extension TradeAssetDetailsBalanceViewModel {
    func storeSnapshot() -> TradeAssetDetailsBalanceSnapshot? {
        guard
            let wallet,
            let typedAssetId,
            let convertedBalance = convertedBalanceStore.getState()[wallet]?.balance
        else {
            return nil
        }

        return makeSnapshot(convertedBalance: convertedBalance, identifier: typedAssetId)
    }
}

private extension TradeAssetDetailsBalanceViewModel {
    func makeSnapshot(
        convertedBalance: ConvertedBalance,
        identifier: TradingAssetToken
    ) -> TradeAssetDetailsBalanceSnapshot? {
        switch identifier {
        case .ton:
            let item = convertedBalance.tonBalance
            return TradeAssetDetailsBalanceSnapshot(
                symbol: TonInfo.symbol,
                imageURL: nil,
                amount: BigUInt(max(item.tonBalance.amount, 0)),
                fractionDigits: TonInfo.fractionDigits,
                convertedAmount: convertedAmount(value: item.converted, price: item.price),
                tagText: nil
            )

        case let .jetton(address):
            guard let item = convertedBalance.jettonsBalance.first(where: {
                $0.jettonBalance.item.jettonInfo.address == address
            }) else {
                return nil
            }
            let jettonInfo = item.jettonBalance.item.jettonInfo
            let displayAmount = item.jettonBalance.scaledBalance ?? item.jettonBalance.quantity
            return TradeAssetDetailsBalanceSnapshot(
                symbol: jettonInfo.symbol ?? "",
                imageURL: jettonInfo.imageURL,
                amount: displayAmount,
                fractionDigits: jettonInfo.fractionDigits,
                convertedAmount: convertedAmount(value: item.converted, price: item.price),
                tagText: jettonInfo.tag
            )

        case .tronUsdt:
            guard let item = convertedBalance.tronUSDT else {
                return nil
            }
            return TradeAssetDetailsBalanceSnapshot(
                symbol: TronSwift.USDT.symbol,
                imageURL: TronSwift.USDT.imageURL,
                amount: item.amount,
                fractionDigits: TronSwift.USDT.fractionDigits,
                convertedAmount: convertedAmount(value: item.converted, price: item.price),
                tagText: TronSwift.USDT.tag
            )
        }
    }

    /// The store encodes "no rate available" as a zero price (and a zero converted
    /// value). Preserve the previous behaviour of hiding the fiat line in that case
    /// instead of rendering a misleading "0".
    func convertedAmount(value: Decimal, price: Decimal) -> Decimal? {
        price == 0 ? nil : value
    }
}
