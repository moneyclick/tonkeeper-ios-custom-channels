import TonAPI

public extension StakingPoolImplementation {
    init(from: PoolImplementationType) {
        switch from {
        case .tf:
            self = .tf
        case .liquidtf:
            self = .liquidTF
        case .ffvault:
            self = .unknown
        case .whales:
            self = .whales
        case .unknownDefaultOpenApi:
            self = .unknown
        }
    }
}
