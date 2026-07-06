@preconcurrency import BigInt
import Foundation

// MARK: - Common

public struct MultichainHealth: Equatable, Sendable {
    public let ok: Bool

    public init(ok: Bool) {
        self.ok = ok
    }
}

public enum MultichainNetwork: String, Sendable, Equatable, Codable {
    case mainnet
    case testnet
}

public struct MultichainNode: Equatable, Sendable {
    public let chain: MultichainChain
    public let network: MultichainNetwork
    public let name: String

    public init(chain: MultichainChain, network: MultichainNetwork, name: String) {
        self.chain = chain
        self.network = network
        self.name = name
    }
}

public enum MultichainNodesResponse: Equatable, Sendable {
    case full(nodes: [MultichainNode], eTag: String?)
    case notModified
}

// MARK: - Assets

public struct MultichainAssetDetails: Hashable, Sendable {
    public let assetId: String
    public let name: String
    public let symbol: String
    public let decimals: Int
    public let image: String

    public init(assetId: String, name: String, symbol: String, decimals: Int, image: String) {
        self.assetId = assetId
        self.name = name
        self.symbol = symbol
        self.decimals = decimals
        self.image = image
    }
}

public struct MultichainAssetPrice: Equatable, Sendable {
    public let prices: [String: Double]
    public let diff24h: [String: String]
    public let diff7d: [String: String]
    public let diff30d: [String: String]

    public init(
        prices: [String: Double],
        diff24h: [String: String],
        diff7d: [String: String],
        diff30d: [String: String]
    ) {
        self.prices = prices
        self.diff24h = diff24h
        self.diff7d = diff7d
        self.diff30d = diff30d
    }
}

public struct MultichainAsset: Equatable, Sendable {
    public let asset: MultichainAssetDetails
    public let price: MultichainAssetPrice
    public let isHidden: Bool
    public let balance: BigUInt
    public let marketCap: [String: String]

    public init(
        asset: MultichainAssetDetails,
        price: MultichainAssetPrice,
        isHidden: Bool = false,
        balance: BigUInt,
        marketCap: [String: String] = [:]
    ) {
        self.asset = asset
        self.price = price
        self.isHidden = isHidden
        self.balance = balance
        self.marketCap = marketCap
    }
}

public enum MultichainAssetSearchSort: String, Sendable, Equatable {
    case marketCap = "market_cap"
    case volume
}

public enum MultichainAssetFilterAction: String, Sendable, Equatable, Codable {
    case show
    case hide
}

public struct MultichainAssetFilterChange: Equatable, Sendable {
    public let assetId: String
    public let action: MultichainAssetFilterAction

    public init(assetId: String, action: MultichainAssetFilterAction) {
        self.assetId = assetId
        self.action = action
    }
}

public struct MultichainAccount: Equatable, Sendable {
    public let chain: MultichainChain
    public let network: MultichainNetwork?
    public let address: String

    public init(chain: MultichainChain, network: MultichainNetwork?, address: String) {
        self.chain = chain
        self.network = network
        self.address = address
    }
}

// MARK: - Fees & broadcast

public struct MultichainFeeEstimate: Equatable, Sendable {
    public let slow: String
    public let normal: String
    public let fast: String

    public init(slow: String, normal: String, fast: String) {
        self.slow = slow
        self.normal = normal
        self.fast = fast
    }
}

public struct MultichainBroadcastResult: Equatable, Sendable {
    public let txHash: String

    public init(txHash: String) {
        self.txHash = txHash
    }
}

public struct MultichainWalletAccount: Equatable, Sendable {
    public let chain: MultichainChain
    public let address: String

    public init(chain: MultichainChain, address: String) {
        self.chain = chain
        self.address = address
    }
}

public struct MultichainRegisteredWallet: Equatable, Sendable {
    public let walletId: String
    public let createdAt: Date
    public let accounts: [MultichainWalletAccount]

    public init(walletId: String, createdAt: Date, accounts: [MultichainWalletAccount]) {
        self.walletId = walletId
        self.createdAt = createdAt
        self.accounts = accounts
    }
}

public struct MultichainWalletAssetsPage: Equatable, Sendable {
    public let assets: [MultichainAsset]
    public let nextCursor: String?
    /// Fiat conversion rates per currency code (e.g. USD), as returned by the API.
    public let fiatPrice: [String: String]

    public init(assets: [MultichainAsset], nextCursor: String?, fiatPrice: [String: String]) {
        self.assets = assets
        self.nextCursor = nextCursor
        self.fiatPrice = fiatPrice
    }
}

// MARK: - Activities

public enum MultichainActivityType: String, Sendable, Equatable, Codable {
    case send
    case receive
    case swap
}

public enum MultichainActivityStatus: String, Sendable, Equatable, Codable {
    case pending
    case confirmed
    case failed
    case dropped
}

public enum MultichainActivityDirection: String, Sendable, Equatable, Codable {
    case incoming = "in"
    case outgoing = "out"
    case selfTransfer = "self"
}

public struct MultichainActivity: Hashable, Sendable {
    public let activityType: MultichainActivityType
    public let status: MultichainActivityStatus
    public let blockTime: Date
    public let blockNumber: Int64?
    public let fromChain: MultichainChain
    public let toChain: MultichainChain
    public let walletAddress: String?
    public let direction: MultichainActivityDirection
    public let fromAddress: String?
    public let toAddress: String?
    public let outToken: MultichainAssetDetails?
    public let outAmount: String?
    public let outAmountUsd: Double?
    public let inToken: MultichainAssetDetails?
    public let inAmount: String?
    public let inAmountUsd: Double?
    public let feeToken: MultichainAssetDetails?
    public let feeAmount: String?
    public let feeAmountUsd: Double?
    public let protocolName: String?
    public let txIds: [String]
    public let isRead: Bool?

    public init(
        activityType: MultichainActivityType,
        status: MultichainActivityStatus,
        blockTime: Date,
        blockNumber: Int64?,
        fromChain: MultichainChain,
        toChain: MultichainChain,
        walletAddress: String?,
        direction: MultichainActivityDirection,
        fromAddress: String?,
        toAddress: String?,
        outToken: MultichainAssetDetails?,
        outAmount: String?,
        outAmountUsd: Double?,
        inToken: MultichainAssetDetails?,
        inAmount: String?,
        inAmountUsd: Double?,
        feeToken: MultichainAssetDetails?,
        feeAmount: String?,
        feeAmountUsd: Double?,
        protocolName: String?,
        txIds: [String],
        isRead: Bool?
    ) {
        self.activityType = activityType
        self.status = status
        self.blockTime = blockTime
        self.blockNumber = blockNumber
        self.fromChain = fromChain
        self.toChain = toChain
        self.walletAddress = walletAddress
        self.direction = direction
        self.fromAddress = fromAddress
        self.toAddress = toAddress
        self.outToken = outToken
        self.outAmount = outAmount
        self.outAmountUsd = outAmountUsd
        self.inToken = inToken
        self.inAmount = inAmount
        self.inAmountUsd = inAmountUsd
        self.feeToken = feeToken
        self.feeAmount = feeAmount
        self.feeAmountUsd = feeAmountUsd
        self.protocolName = protocolName
        self.txIds = txIds
        self.isRead = isRead
    }
}

public struct MultichainWalletActivitiesPage: Equatable, Sendable {
    public let activities: [MultichainActivity]
    public let nextCursor: String?

    public init(activities: [MultichainActivity], nextCursor: String?) {
        self.activities = activities
        self.nextCursor = nextCursor
    }
}
