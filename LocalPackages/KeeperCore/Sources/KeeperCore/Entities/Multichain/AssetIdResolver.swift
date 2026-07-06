import TKLogging
import TronSwift
import UIKit

public enum AssetIdResolver {
    public static func chartIdentifier(for assetId: String) -> String? {
        guard let components = AssetIdComponents(assetId: assetId) else {
            return nil
        }
        switch components {
        case let .coin(chain, _, _):
            let normalizedChain = chain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            switch normalizedChain {
            case "ton":
                return TonInfo.symbol
            default:
                return nil
            }
        case let .asset(chain, _, _, address):
            let normalizedChain = chain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            switch normalizedChain {
            case "tron":
                return JettonMasterAddress.tonUSDT.toRaw()
            default:
                return address
            }
        }
    }
}

public enum AssetIdComponents {
    case coin(chain: String, network: String, coin: String)
    case asset(chain: String, network: String, type: String, address: String)

    public init?(assetId: String) {
        let components = assetId.split(
            separator: "/",
            omittingEmptySubsequences: true
        ).map {
            String($0)
        }
        switch components.count {
        case 3:
            self = .coin(
                chain: components[0],
                network: components[1],
                coin: components[2]
            )
        case 4:
            self = .asset(
                chain: components[0],
                network: components[1],
                type: components[2],
                address: components[3]
            )
        default:
            Log.w("invalid asset id type \(assetId): wrong components count")
            return nil
        }
    }

    public var chain: String {
        switch self {
        case let .coin(chain, _, _):
            chain
        case let .asset(chain, _, _, _):
            chain
        }
    }
}
