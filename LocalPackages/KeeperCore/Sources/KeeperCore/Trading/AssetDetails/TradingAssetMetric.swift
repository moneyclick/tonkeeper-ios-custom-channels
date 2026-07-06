import Foundation
import TKLocalize

public enum TradingAssetMetric: Equatable, Identifiable, Sendable {
    case circulatingSupply(value: String)
    case totalSupply(value: String)
    case marketCap(
        value: String,
        secondaryValue: String? = nil,
        secondaryValueIsPositive: Bool = true
    )
}

public extension TradingAssetMetric {
    var id: String {
        switch self {
        case .circulatingSupply:
            return "circulating_supply"
        case .totalSupply:
            return "total_supply"
        case .marketCap:
            return "market_cap"
        }
    }

    var title: String {
        switch self {
        case .circulatingSupply:
            return TKLocales.Trade.AssetDetails.Overview.circulatingSupply
        case .totalSupply:
            return TKLocales.Trade.AssetDetails.Overview.totalSupply
        case .marketCap:
            return TKLocales.Trade.AssetDetails.Overview.marketCap
        }
    }

    var hint: String {
        switch self {
        case .circulatingSupply:
            return TKLocales.Trade.AssetDetails.Overview.circulatingSupplyHint
        case .totalSupply:
            return TKLocales.Trade.AssetDetails.Overview.totalSupplyHint
        case .marketCap:
            return TKLocales.Trade.AssetDetails.Overview.marketCapHint
        }
    }

    var value: String {
        switch self {
        case let .circulatingSupply(value),
             let .totalSupply(value),
             let .marketCap(value, _, _):
            return value
        }
    }

    var secondaryValue: String? {
        switch self {
        case let .marketCap(_, secondaryValue, _):
            return secondaryValue
        case .circulatingSupply, .totalSupply:
            return nil
        }
    }

    var secondaryValueIsPositive: Bool {
        switch self {
        case let .marketCap(_, _, secondaryValueIsPositive):
            return secondaryValueIsPositive
        case .circulatingSupply, .totalSupply:
            return false
        }
    }

    var showsInfoIcon: Bool {
        switch self {
        case .marketCap:
            return true
        case .circulatingSupply, .totalSupply:
            return false
        }
    }
}
