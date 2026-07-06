public enum LoadShelvesFailure: Error {
    case networkError
    case apiError(
        message: String?
    )
}

public protocol TradingShelvesService {
    var shelves: TradingShelvesSnapshot? { get async }

    func loadShelves() async throws(LoadShelvesFailure) -> TradingShelvesSnapshot
}
