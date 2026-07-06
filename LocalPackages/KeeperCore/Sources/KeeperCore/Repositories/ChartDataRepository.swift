import Foundation
import KeeperCoreComponents
import TonSwift

protocol ChartDataRepository {
    func getChartData(period: Period, token: String, currency: Currency, network: Network) -> [Coordinate]
    func saveChartData(coordinates: [Coordinate], period: Period, token: String, currency: Currency, network: Network) throws
}

struct ChartDataRepositoryImplementation: ChartDataRepository {
    func getChartData(period: Period, token: String, currency: Currency, network: Network) -> [Coordinate] {
        Self.sessionCache.chartData(
            forKey: cacheKey(
                period: period,
                token: token,
                currency: currency,
                network: network
            )
        )
    }

    func saveChartData(coordinates: [Coordinate], period: Period, token: String, currency: Currency, network: Network) throws {
        Self.sessionCache.setChartData(
            coordinates,
            forKey: cacheKey(
                period: period,
                token: token,
                currency: currency,
                network: network
            )
        )
    }
}

struct PersistentChartDataRepositoryImplementation: ChartDataRepository {
    let fileSystemVault: FileSystemVault<[Coordinate], String>

    func getChartData(period: Period, token: String, currency: Currency, network: Network) -> [Coordinate] {
        do {
            return try fileSystemVault.loadItem(
                key: cacheKey(
                    period: period,
                    token: token,
                    currency: currency,
                    network: network
                )
            )
        } catch {
            return []
        }
    }

    func saveChartData(coordinates: [Coordinate], period: Period, token: String, currency: Currency, network: Network) throws {
        try fileSystemVault.saveItem(
            coordinates,
            key: cacheKey(
                period: period,
                token: token,
                currency: currency,
                network: network
            )
        )
    }
}

private extension ChartDataRepository {
    func cacheKey(period: Period, token: String, currency: Currency, network: Network) -> String {
        "\(period.stringValue)_\(currency.code)_\(token)_\(network.rawValue)"
    }
}

private extension ChartDataRepositoryImplementation {
    static let sessionCache = SessionCache()

    final class SessionCache {
        private let lock = NSLock()
        private var storage = [String: [Coordinate]]()

        func chartData(forKey key: String) -> [Coordinate] {
            lock.lock()
            defer { lock.unlock() }
            return storage[key] ?? []
        }

        func setChartData(_ coordinates: [Coordinate], forKey key: String) {
            lock.lock()
            defer { lock.unlock() }
            storage[key] = coordinates
        }
    }
}
