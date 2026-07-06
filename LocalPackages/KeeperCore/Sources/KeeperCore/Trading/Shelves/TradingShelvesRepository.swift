import Foundation

protocol TradingShelvesRepository: AnyObject {
    func shelvesSnapshot() async -> TradingShelvesSnapshot?
    func setShelvesSnapshot(_ value: TradingShelvesSnapshot) async
}

actor TradingShelvesRepositoryImplementation {
    private var cachedShelvesSnapshot: TradingShelvesSnapshot?

    init() {}
}

extension TradingShelvesRepositoryImplementation: TradingShelvesRepository {
    func shelvesSnapshot() -> TradingShelvesSnapshot? {
        cachedShelvesSnapshot
    }

    func setShelvesSnapshot(_ value: TradingShelvesSnapshot) {
        cachedShelvesSnapshot = value
    }
}
