@testable import App
@testable import KeeperCore
import KeeperCoreSensitive
import TonSwift
import XCTest

final class MnemonicDerivationAnalyticsCounterTests: XCTestCase {
    func test_countWalletsAtStartupIfNeeded_sendsEventWithDerivationCounts() async throws {
        let userDefaults = makeUserDefaults(suiteName: #function)
        defer { resetUserDefaults(suiteName: #function) }

        let bip39SoftWallet = try makeWallet(id: "wallet-bip39soft", revision: .v4R2)
        let unknownWallet = try makeWallet(id: "wallet-unknown", revision: .v5R1)
        let tonWallet = try makeWallet(id: "wallet-ton", revision: .v4R1)

        let tracker = MnemonicDerivationAnalyticsCounter(
            dependencies: MnemonicDerivationAnalyticsCounterDependencies(
                logEvent: analyticsSpy.log,
                getMnemonic: mnemonicSpy.getMnemonic,
                getWallets: { [bip39SoftWallet, unknownWallet, tonWallet] in
                    [bip39SoftWallet, unknownWallet, tonWallet]
                },
                getHistoryState: historySpy.getHistoryState,
                getImportedWallets: importedWalletsSpy.getImportedWallets,
                userDefaults: userDefaults
            )
        )

        mnemonicSpy.mnemonics = [
            bip39SoftWallet.id: CoreMnemonic(
                mnemonicWords: Array(repeating: "abandon", count: 12),
                type: .bip39soft
            ),
            unknownWallet.id: CoreMnemonic(
                mnemonicWords: ["custom", "words", "stay", "as", "is"],
                type: .unknown
            ),
            tonWallet.id: CoreMnemonic(
                mnemonicWords: TonSwift.Mnemonic.mnemonicNew(),
                type: .ton
            ),
        ]
        historySpy.historyByWalletId = [
            bip39SoftWallet.id: .empty,
            unknownWallet.id: .nonEmpty,
        ]

        await tracker.countWalletsAtStartupIfNeeded(passcode: "1234")
        userDefaults.synchronize()

        XCTAssertEqual(analyticsSpy.loggedEvents.count, 1)
        let event = try XCTUnwrap(analyticsSpy.loggedEvents.first)
        XCTAssertEqual(event.name, "custom_error")
        XCTAssertEqual(
            event.args["error_message"] as? String,
            "unexpected_mnemonic_derivation_detected"
        )
        let metadata = try parseMetadata(event: event)
        XCTAssertEqual(metadata["bip39soft_empty_history"], 1)
        XCTAssertEqual(metadata["unknown_non_empty_history"], 1)
        XCTAssertNil(metadata["bip39soft_non_empty_history"])
        XCTAssertNil(metadata["unknown_empty_history"])
        XCTAssertEqual(historySpy.checkedWalletIds, [bip39SoftWallet.id, unknownWallet.id])

        let processedIdentifiers = Set(
            userDefaults.stringArray(
                forKey: "v1_processed_mnemonic_derivation_wallet_identifiers"
            ) ?? []
        )
        XCTAssertEqual(
            processedIdentifiers,
            try [
                bip39SoftWallet.address.toRaw(),
                unknownWallet.address.toRaw(),
                tonWallet.address.toRaw(),
            ]
        )
        XCTAssertTrue(
            userDefaults.bool(
                forKey: "v1_did_check_mnemonic_derivation_wallets_at_startup"
            )
        )
    }

    func test_countWalletsAtStartupIfNeeded_marksHealthyWalletsAsProcessedWithoutEvent() async throws {
        let userDefaults = makeUserDefaults(suiteName: #function)
        defer { resetUserDefaults(suiteName: #function) }

        let tonWallet = try makeWallet(id: "wallet-ton", revision: .v4R2)
        let bip39Wallet = try makeWallet(id: "wallet-bip39", revision: .v5R1)

        let tracker = MnemonicDerivationAnalyticsCounter(
            dependencies: MnemonicDerivationAnalyticsCounterDependencies(
                logEvent: analyticsSpy.log,
                getMnemonic: mnemonicSpy.getMnemonic,
                getWallets: { [tonWallet, bip39Wallet] in
                    [tonWallet, bip39Wallet]
                },
                getHistoryState: historySpy.getHistoryState,
                getImportedWallets: importedWalletsSpy.getImportedWallets,
                userDefaults: userDefaults
            )
        )

        mnemonicSpy.mnemonics = [
            tonWallet.id: CoreMnemonic(
                mnemonicWords: TonSwift.Mnemonic.mnemonicNew(),
                type: .ton
            ),
            bip39Wallet.id: CoreMnemonic(
                mnemonicWords: [
                    "abandon", "abandon", "abandon", "abandon",
                    "abandon", "abandon", "abandon", "abandon",
                    "abandon", "abandon", "abandon", "about",
                ],
                type: .bip39
            ),
        ]

        await tracker.countWalletsAtStartupIfNeeded(passcode: "1234")
        userDefaults.synchronize()

        XCTAssertTrue(analyticsSpy.loggedEvents.isEmpty)
        XCTAssertTrue(historySpy.checkedWalletIds.isEmpty)
        XCTAssertEqual(
            Set(
                userDefaults.stringArray(
                    forKey: "v1_processed_mnemonic_derivation_wallet_identifiers"
                ) ?? []
            ),
            try [
                tonWallet.address.toRaw(),
                bip39Wallet.address.toRaw(),
            ]
        )
        XCTAssertTrue(
            userDefaults.bool(
                forKey: "v1_did_check_mnemonic_derivation_wallets_at_startup"
            )
        )
    }

    func test_checkImportedWallets_sendsEventForSelectedRevisionsOnly() async throws {
        let userDefaults = makeUserDefaults(suiteName: #function)
        defer { resetUserDefaults(suiteName: #function) }

        let mnemonic = CoreMnemonic(
            mnemonicWords: Array(repeating: "abandon", count: 12),
            type: .bip39soft
        )
        let revisions: [WalletContractVersion] = [.v4R2, .v5R1]
        let accounts = try makeAccounts(
            mnemonic: mnemonic,
            revisions: revisions,
            network: .mainnet
        )
        importedWalletsSpy.modelsById = Dictionary(
            uniqueKeysWithValues: [
                makeActiveWalletModel(
                    address: accounts[0].address,
                    revision: accounts[0].revision,
                    history: .empty
                ),
                makeActiveWalletModel(
                    address: accounts[1].address,
                    revision: accounts[1].revision,
                    history: .unknown
                ),
            ].map { ($0.id, $0) }
        )
        let tracker = MnemonicDerivationAnalyticsCounter(
            dependencies: MnemonicDerivationAnalyticsCounterDependencies(
                logEvent: analyticsSpy.log,
                getMnemonic: mnemonicSpy.getMnemonic,
                getWallets: { [] },
                getHistoryState: historySpy.getHistoryState,
                getImportedWallets: importedWalletsSpy.getImportedWallets,
                userDefaults: userDefaults
            )
        )

        await tracker.checkImportedWallets(
            mnemonic: mnemonic,
            revisions: revisions,
            network: .mainnet
        )
        userDefaults.synchronize()

        XCTAssertEqual(analyticsSpy.loggedEvents.count, 1)
        let metadata = try parseMetadata(event: XCTUnwrap(analyticsSpy.loggedEvents.first))
        XCTAssertEqual(metadata["bip39soft_empty_history"], 1)
        XCTAssertEqual(metadata["bip39soft_unknown_history"], 1)
        XCTAssertNil(metadata["bip39soft_non_empty_history"])
        XCTAssertEqual(importedWalletsSpy.requestedAccountIds, accounts.map(\.id))
        XCTAssertEqual(
            Set(
                userDefaults.stringArray(
                    forKey: "v1_processed_mnemonic_derivation_wallet_identifiers"
                ) ?? []
            ),
            Set(accounts.map(\.id))
        )
    }

    func test_checkImportedWallets_marksHistoryAsUnknownWhenLookupFails() async throws {
        let userDefaults = makeUserDefaults(suiteName: #function)
        defer { resetUserDefaults(suiteName: #function) }

        let mnemonic = CoreMnemonic(
            mnemonicWords: Array(repeating: "abandon", count: 12),
            type: .bip39soft
        )
        let revisions: [WalletContractVersion] = [.v4R2, .v5R1]
        importedWalletsSpy.error = TestError.importLookupFailed
        let tracker = MnemonicDerivationAnalyticsCounter(
            dependencies: MnemonicDerivationAnalyticsCounterDependencies(
                logEvent: analyticsSpy.log,
                getMnemonic: mnemonicSpy.getMnemonic,
                getWallets: { [] },
                getHistoryState: historySpy.getHistoryState,
                getImportedWallets: importedWalletsSpy.getImportedWallets,
                userDefaults: userDefaults
            )
        )

        await tracker.checkImportedWallets(
            mnemonic: mnemonic,
            revisions: revisions,
            network: .mainnet
        )

        let metadata = try parseMetadata(event: XCTUnwrap(analyticsSpy.loggedEvents.first))
        XCTAssertEqual(metadata["bip39soft_unknown_history"], 2)
    }

    private let analyticsSpy = AnalyticsLoggerSpy()
    private let mnemonicSpy = MnemonicsRepositorySpy()
    private let historySpy = WalletHistorySpy()
    private let importedWalletsSpy = ImportedWalletsSpy()
}

private extension MnemonicDerivationAnalyticsCounterTests {
    func parseMetadata(
        event: (name: String, args: [String: Any])
    ) throws -> [String: Int] {
        let otherMetadata = try XCTUnwrap(event.args["other_metadata"] as? String)
        let otherMetadataData = try XCTUnwrap(otherMetadata.data(using: .utf8))
        return try XCTUnwrap(
            JSONSerialization.jsonObject(with: otherMetadataData) as? [String: Int]
        )
    }

    func makeUserDefaults(suiteName: String) -> UserDefaults {
        let normalizedSuiteName = normalizedSuiteName(for: suiteName)
        let userDefaults = UserDefaults(suiteName: normalizedSuiteName) ?? .standard
        userDefaults.removePersistentDomain(forName: normalizedSuiteName)
        return userDefaults
    }

    func resetUserDefaults(suiteName: String) {
        let normalizedSuiteName = normalizedSuiteName(for: suiteName)
        UserDefaults(suiteName: normalizedSuiteName)?.removePersistentDomain(forName: normalizedSuiteName)
    }

    func normalizedSuiteName(for suiteName: String) -> String {
        "com.tonkeeper.tests." + suiteName
            .replacingOccurrences(of: "[^A-Za-z0-9_.-]", with: "_", options: .regularExpression)
    }

    func makeWallet(
        id: String,
        revision: WalletContractVersion
    ) throws -> Wallet {
        let publicKeyData = {
            let raw = Data((id + "-public-key").utf8)
            let padded = raw + Data(repeating: 0, count: max(0, 32 - raw.count))
            return Data(padded.prefix(32))
        }()
        let publicKey = TonSwift.PublicKey(data: publicKeyData)

        return Wallet(
            id: id,
            identity: WalletIdentity(network: .mainnet, kind: .Regular(publicKey, revision)),
            metaData: WalletMetaData(label: id, tintColor: .SteelGray, icon: .icon(.wallet)),
            setupSettings: WalletSetupSettings(),
            batterySettings: BatterySettings()
        )
    }

    func makeAccounts(
        mnemonic: CoreMnemonic,
        revisions: [WalletContractVersion],
        network: Network
    ) throws -> [(id: String, address: Address, revision: WalletContractVersion)] {
        let publicKey = try mnemonic.toKeyPair().publicKey
        return try revisions.map { revision in
            let address = try createAddress(
                publicKey: publicKey,
                revision: revision,
                network: network
            )
            return (id: address.toRaw(), address: address, revision: revision)
        }
    }

    func createAddress(
        publicKey: TonSwift.PublicKey,
        revision: WalletContractVersion,
        network: Network
    ) throws -> Address {
        let networkRawValue = network.walletNetworkGlobalId

        let contract: WalletContract
        switch revision {
        case .v5R1:
            contract = WalletV5R1(
                publicKey: publicKey.data,
                walletId: WalletId(networkGlobalId: Int32(networkRawValue), workchain: 0)
            )
        case .v5Beta:
            contract = WalletV5Beta(
                publicKey: publicKey.data,
                walletId: WalletIdBeta(networkGlobalId: Int32(networkRawValue), workchain: 0)
            )
        case .v4R2:
            contract = WalletV4R2(publicKey: publicKey.data)
        case .v4R1:
            contract = WalletV4R1(publicKey: publicKey.data)
        case .v3R2:
            contract = try WalletV3(
                workchain: 0,
                publicKey: publicKey.data,
                revision: .r2
            )
        case .v3R1:
            contract = try WalletV3(
                workchain: 0,
                publicKey: publicKey.data,
                revision: .r1
            )
        }
        return try contract.address()
    }

    func makeActiveWalletModel(
        address: Address,
        revision: WalletContractVersion,
        history: ActiveWalletTransactionHistory
    ) -> ActiveWalletModel {
        ActiveWalletModel(
            id: address.toRaw(),
            revision: revision,
            address: address,
            isActive: true,
            balance: Balance(
                tonBalance: TonBalance(amount: 0),
                jettonsBalance: []
            ),
            nfts: [],
            history: history
        )
    }
}

private final class MnemonicsRepositorySpy {
    var mnemonics: [String: CoreMnemonic] = [:]

    func getMnemonic(wallet: Wallet, password _: String) async throws -> CoreMnemonic {
        guard let mnemonic = mnemonics[wallet.id] else {
            throw TestError.missingMnemonic
        }
        return mnemonic
    }
}

private final class WalletHistorySpy {
    var historyByWalletId: [String: ActiveWalletTransactionHistory] = [:]
    private(set) var checkedWalletIds = [String]()

    func getHistoryState(wallet: Wallet) async -> ActiveWalletTransactionHistory {
        checkedWalletIds.append(wallet.id)
        return historyByWalletId[wallet.id] ?? .unknown
    }
}

private final class ImportedWalletsSpy {
    var modelsById: [String: ActiveWalletModel] = [:]
    var error: Error?
    private(set) var requestedAccountIds = [String]()

    func getImportedWallets(
        accounts: [(id: String, address: Address, revision: WalletContractVersion)],
        network _: Network
    ) async throws -> [ActiveWalletModel] {
        requestedAccountIds = accounts.map(\.id)
        if let error {
            throw error
        }
        return accounts.compactMap { modelsById[$0.id] }
    }
}

private final class AnalyticsLoggerSpy {
    private(set) var loggedEvents = [(name: String, args: [String: Any])]()

    func log(_ event: Encodable) {
        guard var dict = AnyEncodable(event).asDictionary() else {
            XCTFail("Failed to encode event")
            return
        }

        guard let name = dict.removeValue(forKey: "eventName") as? String else {
            XCTFail("Missing eventName")
            return
        }

        loggedEvents.append((name: name, args: dict))
    }
}

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ value: Encodable) {
        encodeClosure = value.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

private extension AnyEncodable {
    func asDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dict = object as? [String: Any]
        else {
            return nil
        }
        return dict
    }
}

private enum TestError: Error {
    case missingMnemonic
    case importLookupFailed
}
