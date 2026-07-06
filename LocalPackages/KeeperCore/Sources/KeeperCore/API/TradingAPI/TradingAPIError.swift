import Foundation

enum TradingAPIError: Error {
    case badUrl(
        underlying: Error?
    )
    case badStatus(
        message: String
    )
    case badResponse(
        underlying: Error?
    )
    case transportError(
        underlying: Error?
    )
    case unknown(
        underlying: Error?
    )
}

extension TradingAPIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .badUrl(error):
            "bad url, error: \(error?.localizedDescription ?? "nil")"
        case let .badStatus(message):
            message
        case let .badResponse(error):
            "bad response, error: \(error?.localizedDescription ?? "nil")"
        case let .transportError(error):
            "network error, error: \(error?.localizedDescription ?? "nil")"
        case let .unknown(error):
            "unknown error, error: \(error?.localizedDescription ?? "nil")"
        }
    }
}
