import Foundation
import KeeperCore

public extension TransactionSent {
    init(wallet: Wallet, eventType: EventType) {
        self.init(
            eventType: eventType,
            walletInterface: TransactionSent.walletInterface(for: wallet),
            walletChain: .single,
            walletChainId: nil,
            walletNetwork: wallet.network.isMainnet ? .mainnet : .testnet,
            walletSource: TransactionSent.walletSource(for: wallet)
        )
    }

    private static func walletInterface(for wallet: Wallet) -> WalletInterface? {
        guard let version = try? wallet.contractVersion else { return nil }
        switch version {
        case .v3R1: return .v3r1
        case .v3R2: return .v3r2
        case .v4R1: return .v4r1
        case .v4R2: return .v4r2
        case .v5Beta: return .v5beta
        case .v5R1: return .v5r1
        }
    }

    private static func walletSource(for wallet: Wallet) -> WalletSource {
        switch wallet.kind {
        case .regular, .lockup: return .mnemonic
        case .signer: return .signer
        case .ledger: return .ledger
        case .keystone: return .keystone
        case .watchonly: return .watchonly
        }
    }
}

public extension TransactionSent.EventType {
    static func from(sendData: SendData) -> Self {
        switch sendData {
        case let .ton(ton):
            switch ton.item {
            case let .token(token, _):
                switch token {
                case .ton: return .tonTransfer
                case .jetton: return .jettonTransfer
                }
            case .nft:
                return .nftItemTransfer
            }
        case .tron:
            return .unknown
        }
    }

    static func stakingWithdraw(poolImplementation: StackingPoolInfo.Implementation.Kind) -> Self {
        switch poolImplementation {
        case .whales: return .withdrawStakeRequest
        case .tf: return .withdrawStake
        case .liquidTF: return .jettonBurn
        }
    }
}
