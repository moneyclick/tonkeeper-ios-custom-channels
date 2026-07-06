import KeeperCore

extension Token {
    var sendV3Item: SendV3Item {
        switch self {
        case let .ton(tonToken):
            return .ton(.token(tonToken, amount: 0))
        case .tron(.usdt), .tron(.trx):
            return .tron(.usdt(amount: 0))
        }
    }
}
