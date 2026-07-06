import BigInt
import Foundation
import MultichainAPI

extension MultichainChain {
    func toAPIParametersChainPath() -> MultichainAPI.Components.Parameters.ChainPath {
        toAPISchemaChain()
    }

    func toAPISchemaChain() -> MultichainAPI.Components.Schemas.Chain {
        switch self {
        case .ton: .ton
        case .eth: .eth
        case .base: .base
        case .btc: .btc
        case .tron: .tron
        case .sol: .sol
        case .arb: .arb
        case .bsc: .bsc
        }
    }
}

extension MultichainNetwork {
    func toAPISchemaNetwork() -> MultichainAPI.Components.Schemas.Network {
        MultichainAPI.Components.Schemas.Network(rawValue: rawValue)!
    }
}

extension MultichainNode {
    init(api: MultichainAPI.Components.Schemas.ChainNode) {
        self.init(
            chain: MultichainChain(rawValue: api.chain.rawValue)!,
            network: MultichainNetwork(rawValue: api.network.rawValue)!,
            name: api.name
        )
    }
}

extension MultichainAssetDetails {
    init(api: MultichainAPI.Components.Schemas.AssetInfo) {
        self.init(
            assetId: api.asset_id,
            name: api.name,
            symbol: api.symbol,
            decimals: api.decimals,
            image: api.image
        )
    }
}

extension MultichainAssetPrice {
    init(api: MultichainAPI.Components.Schemas.AssetPrice) {
        self.init(
            prices: api.prices?.additionalProperties ?? [:],
            diff24h: api.diff_24h?.additionalProperties ?? [:],
            diff7d: api.diff_7d?.additionalProperties ?? [:],
            diff30d: api.diff_30d?.additionalProperties ?? [:]
        )
    }
}

extension MultichainAsset {
    init(api: MultichainAPI.Components.Schemas.Asset) {
        self.init(
            asset: MultichainAssetDetails(api: api.asset),
            price: MultichainAssetPrice(api: api.price),
            isHidden: api.is_hidden,
            balance: BigUInt(api.balance) ?? .zero,
            marketCap: [:]
        )
    }

    init(api: MultichainAPI.Components.Schemas.SummaryAsset, balance: BigUInt) {
        self.init(
            asset: MultichainAssetDetails(api: api.asset),
            price: MultichainAssetPrice(api: api.price),
            balance: balance,
            marketCap: api.market_cap.additionalProperties
        )
    }
}

extension MultichainFeeEstimate {
    init(api: MultichainAPI.Components.Schemas.FeeEstimate) {
        self.init(slow: api.slow, normal: api.normal, fast: api.fast)
    }
}

extension MultichainBroadcastResult {
    init(api: MultichainAPI.Components.Responses.BroadcastResult.Body.jsonPayload) {
        self.init(txHash: api.txHash)
    }
}

extension MultichainWalletAccount {
    init(api: MultichainAPI.Components.Schemas.WalletAccount) {
        self.init(
            chain: MultichainChain(rawValue: api.chain.rawValue)!,
            address: api.address
        )
    }
}

extension MultichainRegisteredWallet {
    init(api: MultichainAPI.Components.Schemas.Wallet) {
        self.init(
            walletId: api.wallet_id,
            createdAt: api.created_at,
            accounts: api.accounts.map { MultichainWalletAccount(api: $0) }
        )
    }
}

extension MultichainActivity {
    init(api: MultichainAPI.Components.Schemas.Activity) {
        self.init(
            activityType: MultichainActivityType(rawValue: api.activity_type.rawValue)!,
            status: MultichainActivityStatus(rawValue: api.status.rawValue)!,
            blockTime: api.block_time,
            blockNumber: api.block_number,
            fromChain: MultichainChain(rawValue: api.from_chain.rawValue)!,
            toChain: MultichainChain(rawValue: api.to_chain.rawValue)!,
            walletAddress: api.wallet_address,
            direction: MultichainActivityDirection(api: api.direction),
            fromAddress: api.from_address,
            toAddress: api.to_address,
            outToken: api.out_token.map { MultichainAssetDetails(api: $0) },
            outAmount: api.out_amount,
            outAmountUsd: api.out_amount_usd,
            inToken: api.in_token.map { MultichainAssetDetails(api: $0) },
            inAmount: api.in_amount,
            inAmountUsd: api.in_amount_usd,
            feeToken: api.fee_token.map { MultichainAssetDetails(api: $0) },
            feeAmount: api.fee_amount,
            feeAmountUsd: api.fee_amount_usd,
            protocolName: api._protocol,
            txIds: api.tx_ids,
            isRead: api.is_read
        )
    }
}

extension MultichainActivityDirection {
    init(api: MultichainAPI.Components.Schemas.ActivityDirection) {
        switch api {
        case ._in:
            self = .incoming
        case .out:
            self = .outgoing
        case ._self:
            self = .selfTransfer
        }
    }
}

extension MultichainAssetSearchSort {
    func toAPIParametersSort() -> MultichainAPI.Components.Parameters.SortQuery {
        switch self {
        case .marketCap: return .market_cap
        case .volume: return .volume
        }
    }
}

extension MultichainAssetFilterAction {
    func toAPIRequestAction() -> MultichainAPI.Components.RequestBodies.SetAssetFilters
        .jsonPayload
        .changesPayloadPayload
        .actionPayload
    {
        switch self {
        case .show:
            return .show
        case .hide:
            return .hide
        }
    }
}
