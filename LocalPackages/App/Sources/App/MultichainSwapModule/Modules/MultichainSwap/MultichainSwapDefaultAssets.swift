import BigInt
import Foundation
import KeeperCore
import TonSwift

/// Mock
enum MultichainSwapDefaultAssets {
    static func sendAsset(for wallet: Wallet) -> MultichainAsset {
        MultichainAsset(
            asset: MultichainAssetDetails(
                assetId: tonCoinAssetId(for: wallet),
                name: TonInfo.name,
                symbol: TonInfo.symbol,
                decimals: 9,
                image: "https://tonkeeper.com/assets/onramp/tokens/TON.png"
            ),
            price: emptyPrice,
            balance: BigUInt(2345) * BigUInt(1_000_000_000)
        )
    }

    static func receiveAsset(for wallet: Wallet) -> MultichainAsset {
        let net = chainPathSegment(for: wallet.network)
        let jetton = JettonMasterAddress.tonUSDT.toRaw()
        return MultichainAsset(
            asset: MultichainAssetDetails(
                assetId: "ton/\(net)/jetton/\(jetton)",
                name: "Tether USD",
                symbol: "USDT",
                decimals: 6,
                image: "https://tonkeeper.com/assets/onramp/tokens/USDT.png"
            ),
            price: emptyPrice,
            balance: .zero
        )
    }

    private static let emptyPrice = MultichainAssetPrice(
        prices: [:],
        diff24h: [:],
        diff7d: [:],
        diff30d: [:]
    )

    private static func chainPathSegment(for network: Network) -> String {
        switch network {
        case .mainnet, .tetra:
            "mainnet"
        case .testnet:
            "testnet"
        }
    }

    private static func tonCoinAssetId(for wallet: Wallet) -> String {
        "ton/\(chainPathSegment(for: wallet.network))/coin"
    }
}
