@testable import KeeperCore
import KeeperCoreComponents
import TonSwift
import XCTest

final class ChartDataRepositoryTests: XCTestCase {
    func test_repositoryReturnsSavedDataWithinCurrentSession() throws {
        let repository = ChartDataRepositoryImplementation()
        let token = "token-\(UUID().uuidString)"
        let coordinates = [
            Coordinate(x: 1, y: 10),
            Coordinate(x: 2, y: 20),
        ]

        try repository.saveChartData(
            coordinates: coordinates,
            period: .month,
            token: token,
            currency: .USD,
            network: .mainnet
        )

        let loadedCoordinates = repository.getChartData(
            period: .month,
            token: token,
            currency: .USD,
            network: .mainnet
        )

        XCTAssertEqual(loadedCoordinates.map(\.x), coordinates.map(\.x))
        XCTAssertEqual(loadedCoordinates.map(\.y), coordinates.map(\.y))
    }

    func test_repositorySeparatesEntriesByCacheKey() throws {
        let repository = ChartDataRepositoryImplementation()
        let token = "token-\(UUID().uuidString)"

        try repository.saveChartData(
            coordinates: [Coordinate(x: 1, y: 10)],
            period: .month,
            token: token,
            currency: .USD,
            network: .mainnet
        )

        let loadedCoordinates = repository.getChartData(
            period: .week,
            token: token,
            currency: .USD,
            network: .mainnet
        )

        XCTAssertTrue(loadedCoordinates.isEmpty)
    }

    func test_persistentRepositoryReturnsSavedDataAcrossRepositoryInstances() throws {
        let storageDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        addTeardownBlock {
            try? FileManager.default.removeItem(at: storageDirectory)
        }

        let token = "token-\(UUID().uuidString)"
        let coordinates = [
            Coordinate(x: 1, y: 10),
            Coordinate(x: 2, y: 20),
        ]

        let firstRepository = PersistentChartDataRepositoryImplementation(
            fileSystemVault: FileSystemVault(fileManager: .default, directory: storageDirectory)
        )
        try firstRepository.saveChartData(
            coordinates: coordinates,
            period: .month,
            token: token,
            currency: .USD,
            network: .mainnet
        )

        let secondRepository = PersistentChartDataRepositoryImplementation(
            fileSystemVault: FileSystemVault(fileManager: .default, directory: storageDirectory)
        )
        let loadedCoordinates = secondRepository.getChartData(
            period: .month,
            token: token,
            currency: .USD,
            network: .mainnet
        )

        XCTAssertEqual(loadedCoordinates.map(\.x), coordinates.map(\.x))
        XCTAssertEqual(loadedCoordinates.map(\.y), coordinates.map(\.y))
    }
}
