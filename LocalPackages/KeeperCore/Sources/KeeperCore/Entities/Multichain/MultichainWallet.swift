import Foundation

public struct MultichainWalletAddress: Hashable, Codable, Sendable {
    public let chain: MultichainChain
    public let address: String

    public init(chain: MultichainChain, address: String) {
        self.chain = chain
        self.address = address
    }
}

public enum MultichainWallet: Hashable, Codable, Sendable {
    case addresses([MultichainWalletAddress])
    case unavailable
}
