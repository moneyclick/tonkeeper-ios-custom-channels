import TKTradingAPI

public enum TradingAssetCategory: String, CaseIterable, Identifiable, Sendable {
    case all
    case crypto
    case stocks
    case etfs

    public var id: String {
        rawValue
    }
}

extension TradingAssetCategory {
    public init?(assetID: String) {
        let components = assetID.split(separator: "/", omittingEmptySubsequences: true)
        guard components.count >= 3 else {
            return nil
        }

        switch components[2].lowercased() {
        case "coin", "jetton", "token", "tokens":
            self = .crypto
        case "stock", "stocks":
            self = .stocks
        case "etf", "etfs":
            self = .etfs
        default:
            return nil
        }
    }

    init?(tradingApiValue: Components.Schemas.AssetsTab) {
        switch tradingApiValue {
        case .all:
            self = .all
        case .tokens:
            self = .crypto
        case .stocks:
            self = .stocks
        case .etfs:
            self = .etfs
        }
    }

    var tradingApiValue: Components.Schemas.AssetsTab {
        switch self {
        case .all:
            .all
        case .crypto:
            .tokens
        case .stocks:
            .stocks
        case .etfs:
            .etfs
        }
    }
}
