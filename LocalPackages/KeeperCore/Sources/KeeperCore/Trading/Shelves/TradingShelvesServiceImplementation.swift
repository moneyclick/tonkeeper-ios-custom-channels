import TKLogging
import TKTradingAPI

actor TradingShelvesServiceImplementation {
    private let api: TradingAPI
    private let repository: TradingShelvesRepository
    private let requestContextProvider: TradingRequestContextProvider

    init(
        api: TradingAPI,
        repository: TradingShelvesRepository,
        requestContextProvider: TradingRequestContextProvider
    ) {
        self.api = api
        self.repository = repository
        self.requestContextProvider = requestContextProvider
    }
}

extension TradingShelvesServiceImplementation: TradingShelvesService {
    var shelves: TradingShelvesSnapshot? {
        get async {
            await repository.shelvesSnapshot()
        }
    }

    func loadShelves() async throws(LoadShelvesFailure) -> TradingShelvesSnapshot {
        Log.trade.i("load shelves")
        let snapshot: TradingShelvesSnapshot
        do {
            let requestContext = await requestContextProvider.makeRequestContext()
            let response = try await api.getShelves(requestContext: requestContext)
            snapshot = TradingShelvesSnapshot(
                response: response,
                currency: requestContext.currency
            )
        } catch {
            Log.trade.i("load shelves failed \(error.localizedDescription)")
            switch error {
            case .transportError:
                throw .networkError
            default:
                throw .apiError(message: error.localizedDescription)
            }
        }
        await repository.setShelvesSnapshot(snapshot)
        Log.trade.i("load shelves - success")
        return snapshot
    }
}
