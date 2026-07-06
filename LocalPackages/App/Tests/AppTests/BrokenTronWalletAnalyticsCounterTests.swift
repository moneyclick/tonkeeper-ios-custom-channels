@testable import App
@testable import KeeperCore
import TonSwift
import XCTest

final class BrokenTronWalletAnalyticsCounterTests: XCTestCase {
    func test_countWalletsAtStartupIfNeeded_sendsEventForOnlyNewBrokenWalletsAndMarksStartupChecked() async throws {
        let userDefaults = makeUserDefaults(suiteName: #function)
        defer { resetUserDefaults(suiteName: #function) }

        let firstWallet = try makeWallet(
            id: "wallet-1",
            mnemonicWords: TestData.brokenMnemonicWords,
            useLegacyTronAddress: true
        )
        let secondWallet = try makeWallet(
            id: "wallet-2",
            mnemonicWords: TestData.secondBrokenMnemonicWords,
            useLegacyTronAddress: true
        )
        try userDefaults.set(
            [XCTUnwrap(firstWallet.tron?.address.base58)],
            forKey: "v1_processed_tron_wallet_addresses"
        )
        userDefaults.synchronize()

        let analyticsSpy = AnalyticsLoggerSpy()
        let mnemonicsSpy = MnemonicsRepositorySpy(
            mnemonics: [
                firstWallet.id: TestData.brokenMnemonicWords,
                secondWallet.id: TestData.secondBrokenMnemonicWords,
            ]
        )
        let tronApiSpy = try TronTransactionsCheckerSpy(
            hasTransactionsByAddress: [
                XCTUnwrap(firstWallet.tron?.address.base58): true,
                XCTUnwrap(secondWallet.tron?.address.base58): true,
            ]
        )
        let tracker = BrokenTronWalletAnalyticsCounter(
            dependencies: BrokenTronWalletAnalyticsCounterDependencies(
                logEvent: analyticsSpy.log,
                getMnemonicWords: mnemonicsSpy.getMnemonicWords,
                getWallets: { [firstWallet, secondWallet] in
                    [firstWallet, secondWallet]
                },
                hasTransactions: tronApiSpy.hasTransactions,
                userDefaults: userDefaults
            )
        )

        await tracker.countWalletsAtStartupIfNeeded(passcode: "1234")
        userDefaults.synchronize()

        XCTAssertEqual(analyticsSpy.loggedEvents.count, 1)
        let event = try XCTUnwrap(analyticsSpy.loggedEvents.first)
        XCTAssertEqual(event.name, "custom_error")
        XCTAssertEqual(event.args["error_message"] as? String, "tron_broken_address_detected")
        let otherMetadata = try XCTUnwrap(event.args["other_metadata"] as? String)
        let otherMetadataData = try XCTUnwrap(otherMetadata.data(using: .utf8))
        let otherMetadataObject = try XCTUnwrap(
            JSONSerialization.jsonObject(with: otherMetadataData) as? [String: Int]
        )
        XCTAssertEqual(otherMetadataObject["affected_non_empty_history"], 1)
        XCTAssertNil(otherMetadataObject["affected_empty_history"])

        let processedAddresses = Set(
            userDefaults.stringArray(forKey: "v1_processed_tron_wallet_addresses") ?? []
        )
        XCTAssertEqual(
            processedAddresses,
            try [
                XCTUnwrap(firstWallet.tron?.address.base58),
                XCTUnwrap(secondWallet.tron?.address.base58),
            ]
        )
        XCTAssertTrue(userDefaults.bool(forKey: "v1_did_check_broken_tron_wallets_at_startup"))
    }

    func test_countWalletsAtStartupIfNeeded_doesNothingWhenStartupCheckWasAlreadyPerformed() async throws {
        let userDefaults = makeUserDefaults(suiteName: #function)
        defer { resetUserDefaults(suiteName: #function) }

        let wallet = try makeWallet(
            id: "wallet-1",
            mnemonicWords: TestData.brokenMnemonicWords,
            useLegacyTronAddress: true
        )
        userDefaults.set(true, forKey: "v1_did_check_broken_tron_wallets_at_startup")
        userDefaults.synchronize()

        let tronApiSpy = try TronTransactionsCheckerSpy(
            hasTransactionsByAddress: [XCTUnwrap(wallet.tron?.address.base58): true]
        )
        let analyticsSpy = AnalyticsLoggerSpy()
        let mnemonicsSpy = MnemonicsRepositorySpy(
            mnemonics: [wallet.id: TestData.brokenMnemonicWords]
        )
        let tracker = BrokenTronWalletAnalyticsCounter(
            dependencies: BrokenTronWalletAnalyticsCounterDependencies(
                logEvent: analyticsSpy.log,
                getMnemonicWords: mnemonicsSpy.getMnemonicWords,
                getWallets: { [wallet] in
                    [wallet]
                },
                hasTransactions: tronApiSpy.hasTransactions,
                userDefaults: userDefaults
            )
        )

        XCTAssertFalse(tracker.needsStartupCheck)

        await tracker.countWalletsAtStartupIfNeeded(passcode: "1234")
        userDefaults.synchronize()

        XCTAssertTrue(analyticsSpy.loggedEvents.isEmpty)
        XCTAssertTrue(tronApiSpy.checkedAddresses.isEmpty)
    }

    func test_checkImportedMnemonics_sendsEventForBrokenWalletAfterStartupCheck() async throws {
        let userDefaults = makeUserDefaults(suiteName: #function)
        defer { resetUserDefaults(suiteName: #function) }
        userDefaults.set(true, forKey: "v1_did_check_broken_tron_wallets_at_startup")
        userDefaults.synchronize()

        let legacyAddress = try BrokenTronAddress(
            publicKey: TonTron.derivedKeyPair(
                tonMnemonic: TestData.brokenMnemonicWords,
                index: 0,
                useBip39DerivationForBip39Mnemonics: false
            ).publicKey
        )
        let analyticsSpy = AnalyticsLoggerSpy()
        let tronApiSpy = TronTransactionsCheckerSpy(
            hasTransactionsByAddress: [legacyAddress.base58: true]
        )
        let mnemonicsSpy = MnemonicsRepositorySpy(mnemonics: [:])
        let tracker = BrokenTronWalletAnalyticsCounter(
            dependencies: BrokenTronWalletAnalyticsCounterDependencies(
                logEvent: analyticsSpy.log,
                getMnemonicWords: mnemonicsSpy.getMnemonicWords,
                getWallets: {
                    []
                },
                hasTransactions: tronApiSpy.hasTransactions,
                userDefaults: userDefaults
            )
        )

        await tracker.checkImportedMnemonics(words: TestData.brokenMnemonicWords)
        userDefaults.synchronize()

        XCTAssertEqual(analyticsSpy.loggedEvents.count, 1)
        XCTAssertEqual(
            userDefaults.stringArray(forKey: "v1_processed_tron_wallet_addresses"),
            [legacyAddress.base58]
        )
        XCTAssertFalse(tracker.needsStartupCheck)
    }
}

private extension BrokenTronWalletAnalyticsCounterTests {
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
        mnemonicWords: [String],
        useLegacyTronAddress: Bool
    ) throws -> Wallet {
        let tronKeyPair = try TonTron.derivedKeyPair(
            tonMnemonic: mnemonicWords,
            index: 0,
            useBip39DerivationForBip39Mnemonics: !useLegacyTronAddress
        )
        let tonPublicKeyData = {
            let raw = Data((id + "-ton-public-key").utf8)
            let padded = raw + Data(repeating: 0, count: max(0, 32 - raw.count))
            return Data(padded.prefix(32))
        }()
        let tonPublicKey = TonSwift.PublicKey(data: tonPublicKeyData)
        let tron = try WalletTron(
            publicKey: tronKeyPair.publicKey,
            address: .init(publicKey: tronKeyPair.publicKey),
            isOn: true
        )

        return Wallet(
            id: id,
            identity: WalletIdentity(network: .mainnet, kind: .Regular(tonPublicKey, .v4R2)),
            metaData: WalletMetaData(label: id, tintColor: .SteelGray, icon: .icon(.wallet)),
            setupSettings: WalletSetupSettings(),
            batterySettings: BatterySettings(),
            tron: tron
        )
    }
}

private enum TestData {
    static let brokenMnemonicWords = [
        "vanish", "grab", "filter", "unique", "night", "picnic",
        "door", "carpet", "drastic", "artwork", "pioneer", "merry",
    ]

    static let secondBrokenMnemonicWords = [
        "chunk", "dinosaur", "wealth", "clean", "case", "duty",
        "kitchen", "number", "bless", "security", "pistol", "add",
        "club", "boat", "phrase", "doctor", "jacket", "scorpion",
        "gas", "cream", "hurt", "weather", "check", "twelve",
    ]

    static let healthyMnemonicWords = [
        "potato", "kind", "you", "abandon", "curve", "hybrid",
        "approve", "outside", "document", "culture", "edit", "few",
        "fit", "magnet", "tilt", "shrimp", "path", "coil",
        "spin", "always", "robot", "blame", "grace", "beyond",
    ]
}

private final class MnemonicsRepositorySpy {
    let mnemonics: [String: [String]]

    init(mnemonics: [String: [String]]) {
        self.mnemonics = mnemonics
    }

    func getMnemonicWords(wallet: Wallet, password: String) async throws -> [String] {
        guard let mnemonic = mnemonics[wallet.id] else {
            throw TestError.missingMnemonic
        }
        return mnemonic
    }
}

private final class TronTransactionsCheckerSpy {
    let hasTransactionsByAddress: [String: Bool]
    private(set) var checkedAddresses = [String]()

    init(hasTransactionsByAddress: [String: Bool]) {
        self.hasTransactionsByAddress = hasTransactionsByAddress
    }

    func hasTransactions(address: BrokenTronAddress) async throws -> Bool {
        checkedAddresses.append(address.base58)
        guard let value = hasTransactionsByAddress[address.base58] else {
            throw TestError.missingTransactionsFlag
        }
        return value
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
    case missingTransactionsFlag
}
