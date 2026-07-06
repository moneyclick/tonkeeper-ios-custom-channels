import KeeperCore
import TKLogging
import TKUIKit
import TronSwift
import UIKit

extension AssetIdResolver {
    static func tag(for assetId: String) -> String? {
        badgeChain(for: assetId)?.assetIdResolverTag
    }

    static func imageSource(for assetId: String, imageUrl: URL?) -> AssetAvatarViewImageSource {
        guard let typedId = TradingAssetToken(assetId: assetId), case .ton = typedId else {
            return .url(imageUrl, chainIcon: AssetIdResolver.chainIcon(for: assetId))
        }
        return .image(.TKCore.Icons.Size44.tonLogo, chainIcon: nil)
    }

    static func chainIcon(for assetId: String) -> UIImage? {
        badgeChain(for: assetId)?.assetIdResolverImage
    }

    private static func badgeChain(for assetId: String) -> MultichainChain? {
        guard let components = AssetIdComponents(assetId: assetId) else {
            return nil
        }

        switch components {
        case .coin:
            return nil
        case let .asset(chain, _, type, address):
            guard let multichainChain = MultichainChain(assetIdChain: chain) else {
                return nil
            }
            let normalizedType = type.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            switch (multichainChain, normalizedType, address) {
            case (.ton, "jetton", JettonMasterAddress.tonUSDT.toRaw()):
                return .ton
            case (.tron, "token", TronSwift.USDT.address.base58),
                 (.tron, "tokens", TronSwift.USDT.address.base58):
                return .tron
            default:
                return nil
            }
        }
    }

    static func tonPreviewContext(
        wallet: Wallet
    ) -> TradeAssetDetailsViewModel.PreviewContext {
        previewContext(
            assetID: "ton/\(wallet.network.tradeAssetDetailsNetworkIdentifier)/coin",
            title: TonInfo.name,
            imageURL: nil,
            symbol: TonInfo.symbol,
            isUnverified: false
        )
    }

    static func usdtTrc20PreviewContext(
        wallet: Wallet,
        walletTron _: WalletTron
    ) -> TradeAssetDetailsViewModel.PreviewContext {
        previewContext(
            assetID: "tron/\(wallet.network.tradeAssetDetailsNetworkIdentifier)/token/\(TronSwift.USDT.address.base58)",
            title: TronSwift.USDT.name,
            imageURL: nil,
            symbol: TronSwift.USDT.symbol,
            isUnverified: false
        )
    }

    static func jettonPreviewContext(
        wallet: Wallet,
        jettonItem: JettonItem
    ) -> TradeAssetDetailsViewModel.PreviewContext {
        previewContext(
            assetID: "ton/\(wallet.network.tradeAssetDetailsNetworkIdentifier)/jetton/\(jettonItem.jettonInfo.address.toRaw())",
            title: jettonItem.jettonInfo.name,
            imageURL: jettonItem.jettonInfo.imageURL,
            symbol: jettonItem.jettonInfo.symbol,
            isUnverified: jettonItem.jettonInfo.isUnverified
        )
    }

    private static func previewContext(
        assetID: String,
        title: String?,
        imageURL: URL?,
        symbol: String?,
        isUnverified: Bool
    ) -> TradeAssetDetailsViewModel.PreviewContext {
        .init(
            assetID: assetID,
            assetCategory: .crypto,
            title: title,
            imageURL: imageURL,
            isUnverified: isUnverified
        )
    }
}

private extension MultichainChain {
    var assetIdResolverImage: UIImage? {
        switch self {
        case .ton:
            return .TKUIKit.Icons.Size20.tonChain
        case .tron:
            return .TKUIKit.Icons.Size20.trxChain
        default:
            return nil
        }
    }

    var assetIdResolverTag: String? {
        switch self {
        case .ton:
            return TonInfo.chain
        case .tron:
            return TronSwift.USDT.tag
        default:
            return nil
        }
    }
}

private extension Network {
    var tradeAssetDetailsNetworkIdentifier: String {
        switch self {
        case .mainnet, .tetra:
            "mainnet"
        case .testnet:
            "testnet"
        }
    }
}
