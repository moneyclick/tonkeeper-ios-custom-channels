import KeeperCore
import TKLocalize
import TKUIKit
import UIKit

struct AddressConfiguration {
    let title: String
    let icon: UIImage
}

extension MultichainChain {
    var addressConfiguration: AddressConfiguration {
        switch self {
        case .ton:
            AddressConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Ton.title,
                icon: .TKUIKit.Icons.Size20.tonChain
            )
        case .eth:
            AddressConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Ethereum.title,
                icon: .TKUIKit.Icons.Size20.ethChain
            )
        case .btc:
            AddressConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Bitcoin.title,
                icon: .TKUIKit.Icons.Size20.btcChain
            )
        case .base:
            AddressConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Base.title,
                icon: .TKUIKit.Icons.Size20.baseChain
            )
        case .bsc:
            AddressConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Smartchain.title,
                icon: .TKUIKit.Icons.Size20.bscChain
            )
        case .arb:
            AddressConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Arbitrum.title,
                icon: .TKUIKit.Icons.Size20.arbitrumChain
            )
        case .tron:
            AddressConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Tron.title,
                icon: .TKUIKit.Icons.Size20.trxChain
            )
        case .sol:
            AddressConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Solana.title,
                icon: .TKUIKit.Icons.Size20.solChain
            )
        }
    }

    var badgeTitle: String {
        switch self {
        case .ton:
            "TON"
        case .eth:
            "ETHEREUM"
        case .btc:
            "BITCOIN"
        case .base:
            "BASE"
        case .bsc:
            "BSC"
        case .arb:
            "ARBITRUM"
        case .tron:
            "TRON"
        case .sol:
            "SOLANA"
        }
    }

    var symbol: String {
        switch self {
        case .ton:
            "TON"
        case .eth:
            "ETH"
        case .btc:
            "BTC"
        case .base:
            "BASE"
        case .bsc:
            "BSC"
        case .arb:
            "ARB"
        case .tron:
            "TRON"
        case .sol:
            "SOL"
        }
    }

    var tokenType: String {
        switch self {
        case .ton:
            "TON"
        case .eth:
            "ERC20"
        case .btc:
            "BTC"
        case .base:
            "ERC20"
        case .bsc:
            "BEP20"
        case .arb:
            "ERC20"
        case .tron:
            "TRC20"
        case .sol:
            "SPL"
        }
    }
}
