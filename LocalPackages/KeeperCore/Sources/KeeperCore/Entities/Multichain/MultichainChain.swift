public enum MultichainChain: String, Sendable, Equatable, Codable, CaseIterable {
    case ton
    case eth
    case base
    case btc
    case tron
    case sol
    case arb
    case bsc
}

public extension MultichainChain {
    init?(assetIdChain: String) {
        let chain = assetIdChain
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch chain {
        case "trx":
            self = .tron
        default:
            self.init(rawValue: chain)
        }
    }
}

public extension MultichainAssetDetails {
    var chain: MultichainChain? {
        guard let components = AssetIdComponents(assetId: assetId) else {
            return nil
        }
        return MultichainChain(assetIdChain: components.chain)
    }
}
