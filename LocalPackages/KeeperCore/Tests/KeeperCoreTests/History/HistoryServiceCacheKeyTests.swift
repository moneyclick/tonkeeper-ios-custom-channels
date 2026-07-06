@testable import KeeperCore
import TonSwift
import XCTest

final class HistoryServiceCacheKeyTests: XCTestCase {
    func test_allEventsNamespace_usesDifferentKeysForDifferentTronBip39ImportFixValues() throws {
        let repository = HistoryRepositorySpy()
        let wallet = makeWallet(id: "wallet")

        let disabledService = makeHistoryService(
            repository: repository,
            cacheNamespace: .allEvents,
            tronBip39ImportFixEnabled: false
        )
        _ = try disabledService.cachedEvents(wallet: wallet)

        let enabledService = makeHistoryService(
            repository: repository,
            cacheNamespace: .allEvents,
            tronBip39ImportFixEnabled: true
        )
        _ = try enabledService.cachedEvents(wallet: wallet)

        let baseKey = try wallet.friendlyAddress.toString()
        XCTAssertEqual(
            repository.loadedKeys,
            [
                baseKey + ":history-all-events:tron-bip39-import-fix-disabled",
                baseKey + ":history-all-events:tron-bip39-import-fix-enabled",
            ]
        )
    }

    func test_tronUsdtNamespace_usesDedicatedKey() throws {
        let repository = HistoryRepositorySpy()
        let wallet = makeWallet(id: "wallet")
        let service = makeHistoryService(
            repository: repository,
            cacheNamespace: .tronUSDT,
            tronBip39ImportFixEnabled: true
        )

        try service.saveEvents(events: [], wallet: wallet)

        let baseKey = try wallet.friendlyAddress.toString()
        XCTAssertEqual(
            repository.savedKeys,
            [baseKey + ":history-tron-usdt:tron-bip39-import-fix-enabled"]
        )
    }

    func test_jettonCacheKey_doesNotDependOnHistoryNamespace() throws {
        let repository = HistoryRepositorySpy()
        let wallet = makeWallet(id: "wallet")
        let jettonMasterAddress = try Address.parse("EQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM9c")
        let service = makeHistoryService(
            repository: repository,
            cacheNamespace: .allEvents,
            tronBip39ImportFixEnabled: true
        )

        try service.saveEvents(events: [], jettonMasterAddress: jettonMasterAddress, wallet: wallet)

        let baseKey = try wallet.friendlyAddress.toString()
        XCTAssertEqual(
            repository.savedKeys,
            [baseKey + ":" + jettonMasterAddress.toRaw()]
        )
    }
}

private extension HistoryServiceCacheKeyTests {
    func makeHistoryService(
        repository: HistoryRepository,
        cacheNamespace: HistoryServiceImplementation.CacheNamespace,
        tronBip39ImportFixEnabled: Bool
    ) -> HistoryServiceImplementation {
        HistoryServiceImplementation(
            apiProvider: APIProvider { _ in
                fatalError("unused")
            },
            repository: repository,
            cacheNamespace: cacheNamespace,
            tronBip39ImportFixEnabled: tronBip39ImportFixEnabled
        )
    }

    func makeWallet(id: String) -> Wallet {
        let tonPublicKeyData = Data((id + "-ton-public-key").utf8) + Data(repeating: 0, count: 32)
        let tonPublicKey = TonSwift.PublicKey(data: Data(tonPublicKeyData.prefix(32)))
        return Wallet(
            id: id,
            identity: WalletIdentity(network: .mainnet, kind: .Regular(tonPublicKey, .v4R2)),
            metaData: WalletMetaData(label: id, tintColor: .SteelGray, icon: .icon(.wallet)),
            setupSettings: WalletSetupSettings(),
            batterySettings: BatterySettings()
        )
    }
}

private final class HistoryRepositorySpy: HistoryRepository {
    private(set) var savedKeys = [String]()
    private(set) var loadedKeys = [String]()

    func saveEvents(events: [HistoryEvent], forKey key: String) throws {
        savedKeys.append(key)
    }

    func getEvents(forKey key: String) throws -> [HistoryEvent] {
        loadedKeys.append(key)
        return []
    }
}
