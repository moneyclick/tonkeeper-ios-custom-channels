import Foundation
import KeeperCoreComponents
import KeeperCoreSensitive
import Testing
import TKLogging
import TonSwift

@Suite
struct MnemonicsRepositoryV2Tests {
    @Test
    func cryptoRoundTripReturnsOriginalMnemonic() throws {
        let original = CoreMnemonic(
            mnemonicWords: ["one", "two", "three"],
            type: .unknown
        )
        let encrypted = try MnemonicsRepositoryV2Crypto.encrypt(
            original,
            passcode: "1234"
        )

        let decrypted = try MnemonicsRepositoryV2Crypto.decrypt(
            encrypted,
            passcode: "1234"
        )

        #expect(decrypted == original)
    }

    @Test
    func cryptoDecryptFailsWithWrongPasscode() throws {
        let mnemonic = CoreMnemonic(
            mnemonicWords: ["one", "two", "three"],
            type: .unknown
        )
        let encrypted = try MnemonicsRepositoryV2Crypto.encrypt(
            mnemonic,
            passcode: "1234"
        )

        #expect(throws: (any Error).self) {
            try MnemonicsRepositoryV2Crypto.decrypt(encrypted, passcode: "5678")
        }
    }

    @Test
    func guessByWordsReturnsUnknownForInvalidWords() {
        let guessed = DerivationType.guessByWords(["invalid"])
        #expect(guessed == .unknown)
    }

    @Test
    func guessByWordsReturnsBip39SoftForWordsWithoutChecksum() {
        let words = Array(repeating: "abandon", count: 12)

        #expect(BIP39Mnemonic.isValidBip39SoftMnemonic(mnemonicArray: words))
        #expect(!BIP39Mnemonic.isValidBip39Mnemonic(mnemonicArray: words))
        #expect(DerivationType.guessByWords(words) == .bip39soft)
    }

    @Test
    func guessByWordsReturnsBip39ForValidChecksumMnemonic() {
        let words = [
            "abandon", "abandon", "abandon", "abandon",
            "abandon", "abandon", "abandon", "abandon",
            "abandon", "abandon", "abandon", "about",
        ]

        #expect(BIP39Mnemonic.isValidBip39Mnemonic(mnemonicArray: words))
        #expect(DerivationType.guessByWords(words) == .bip39)
    }

    @Test
    func guessByWordsReturnsTonForValidTonMnemonic() {
        let tonWords = TonSwift.Mnemonic.mnemonicNew()

        #expect(TonSwift.Mnemonic.mnemonicValidate(mnemonicArray: tonWords))
        #expect(DerivationType.guessByWords(tonWords) == .ton)
    }

    @Test
    func toKeyPairSupportsBip39SoftMnemonic() throws {
        let mnemonic = CoreMnemonic(
            mnemonicWords: Array(repeating: "abandon", count: 12),
            type: .bip39soft
        )

        _ = try mnemonic.toKeyPair()
    }

    @Test
    func toKeyPairForBip39AndBip39SoftProducesSameKeyPair() throws {
        let words = Array(repeating: "abandon", count: 12)
        let bip39 = CoreMnemonic(
            mnemonicWords: words,
            type: .bip39
        )
        let bip39soft = CoreMnemonic(
            mnemonicWords: words,
            type: .bip39soft
        )

        let bip39KeyPair = try bip39.toKeyPair()
        let bip39softKeyPair = try bip39soft.toKeyPair()

        #expect(bip39KeyPair.publicKey.data == bip39softKeyPair.publicKey.data)
        #expect(bip39KeyPair.privateKey.data == bip39softKeyPair.privateKey.data)
    }

    @Test
    func cryptoRoundTripPreservesUnknownTypeAndInvalidWords() throws {
        let mnemonic = CoreMnemonic(
            mnemonicWords: ["this", "is", "not", "a", "valid", "mnemonic"],
            type: .unknown
        )
        let encrypted = try MnemonicsRepositoryV2Crypto.encrypt(
            mnemonic,
            passcode: "1234"
        )

        let restored = try MnemonicsRepositoryV2Crypto.decrypt(
            encrypted,
            passcode: "1234"
        )
        #expect(restored == mnemonic)
    }

    @Test
    func repositoryPersistsUnknownMnemonicWithoutValidation() throws {
        let mnemonic = CoreMnemonic(
            mnemonicWords: ["this", "is", "not", "a", "valid", "mnemonic"],
            type: .unknown
        )
        let repository = makeRepository(
            passcode: "1234",
            rawStorage: InMemoryRawMnemonicsStorage()
        )

        try repository.upsert(mnemonic, id: "wallet_unknown")

        let restored = try repository.get(id: "wallet_unknown")
        #expect(restored == mnemonic)
    }

    @Test
    func repositoryStoresEachMnemonicBySeparateId() throws {
        let repository = makeRepository(
            passcode: "1234",
            rawStorage: InMemoryRawMnemonicsStorage()
        )
        let firstMnemonic = CoreMnemonic(
            mnemonicWords: Array(repeating: "abandon", count: 12),
            type: .bip39soft
        )
        let secondMnemonic = CoreMnemonic(
            mnemonicWords: ["custom", "words", "are", "kept", "as", "is"],
            type: .unknown
        )

        try repository.add(firstMnemonic, id: "wallet_1")
        try repository.add(secondMnemonic, id: "wallet_2")
        try repository.delete(id: "wallet_1")

        #expect(throws: MnemonicsRepositoryV2GetFailure.self) {
            _ = try repository.get(id: "wallet_1")
        }
        let restoredSecond = try repository.get(id: "wallet_2")
        #expect(restoredSecond == secondMnemonic)
    }

    @Test
    func repositoryGetAllPreservesDerivationTypeForMigratedMnemonics() throws {
        let repository = makeRepository(
            passcode: "1234",
            rawStorage: InMemoryRawMnemonicsStorage()
        )

        let tonWords = TonSwift.Mnemonic.mnemonicNew()
        let tonMnemonic = CoreMnemonic(mnemonicWords: tonWords, type: .ton)
        let bip39Mnemonic = CoreMnemonic(
            mnemonicWords: [
                "abandon", "abandon", "abandon", "abandon",
                "abandon", "abandon", "abandon", "abandon",
                "abandon", "abandon", "abandon", "about",
            ],
            type: .bip39
        )
        let bip39SoftMnemonic = CoreMnemonic(
            mnemonicWords: Array(repeating: "abandon", count: 12),
            type: .bip39soft
        )
        let unknownMnemonic = CoreMnemonic(
            mnemonicWords: ["custom", "words", "that", "stay", "as", "is"],
            type: .unknown
        )

        try repository.upsert(tonMnemonic, id: "wallet_ton")
        try repository.upsert(bip39Mnemonic, id: "wallet_bip39")
        try repository.upsert(bip39SoftMnemonic, id: "wallet_bip39soft")
        try repository.upsert(unknownMnemonic, id: "wallet_unknown")

        let restored = try repository.getAll()

        #expect(restored.count == 4)
        #expect(restored["wallet_ton"] == tonMnemonic)
        #expect(restored["wallet_bip39"] == bip39Mnemonic)
        #expect(restored["wallet_bip39soft"] == bip39SoftMnemonic)
        #expect(restored["wallet_unknown"] == unknownMnemonic)
    }

    @Test
    func repositoryUpsertOverwritesMnemonicForSameId() throws {
        let repository = makeRepository(
            passcode: "1234",
            rawStorage: InMemoryRawMnemonicsStorage()
        )

        let initial = CoreMnemonic(
            mnemonicWords: ["old", "value"],
            type: .unknown
        )
        let updated = CoreMnemonic(
            mnemonicWords: Array(repeating: "abandon", count: 12),
            type: .bip39soft
        )

        try repository.upsert(initial, id: "wallet")
        try repository.upsert(updated, id: "wallet")

        let restored = try repository.get(id: "wallet")
        #expect(restored == updated)
    }

    @Test
    func bip39SoftValidationRequiresDictionaryWordsOnly() {
        let words = ["abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "abandon", "invalid"]
        #expect(!BIP39Mnemonic.isValidBip39SoftMnemonic(mnemonicArray: words))
    }

    @Test
    func toKeyPairThrowsForUnknownDerivationType() {
        let mnemonic = CoreMnemonic(
            mnemonicWords: ["anything"],
            type: .unknown
        )

        do {
            _ = try mnemonic.toKeyPair()
            Issue.record("Expected unknownMnemonicType")
        } catch {
            guard case .unknownMnemonicType = error else {
                Issue.record("Expected unknownMnemonicType, got \(error)")
                return
            }
        }
    }
}

private extension MnemonicsRepositoryV2Tests {
    func makeRepository(
        passcode: String,
        rawStorage: any RawMnemonicsDataRepositoryV2
    ) -> DefaultMnemonicsRepositoryV2 {
        DefaultMnemonicsRepositoryV2(
            encoder: { mnemonic in
                try MnemonicsRepositoryV2Crypto.encrypt(mnemonic, passcode: passcode)
            },
            decoder: { rawData in
                try MnemonicsRepositoryV2Crypto.decrypt(rawData, passcode: passcode)
            },
            rawStorage: rawStorage
        )
    }
}

private final class InMemoryRawMnemonicsStorage: RawMnemonicsDataRepositoryV2 {
    private var store: [CoreMnemonicIdentifier: RawMnemonicsData] = [:]
    private let logger = LogDomain.mnemonicStorage

    func hasMnemonic() throws(MnemonicsRepositoryHasAnyFailure) -> Bool {
        !store.isEmpty
    }

    func add(
        _ mnemonic: RawMnemonicsData,
        id: CoreMnemonicIdentifier
    ) throws(MnemonicsRepositoryV2SaveFailure) {
        guard store[id] == nil else {
            logger.e("InMemoryRawMnemonicsStorage duplicate add attempt. id=\(id)")
            throw .dublicate()
        }
        store[id] = mnemonic
    }

    func upsert(
        _ mnemonic: RawMnemonicsData,
        id: CoreMnemonicIdentifier
    ) throws(MnemonicsRepositoryV2UpsertFailure) {
        store[id] = mnemonic
    }

    func get(id: CoreMnemonicIdentifier) throws(MnemonicsRepositoryV2GetFailure) -> RawMnemonicsData {
        guard let value = store[id] else {
            logger.e("InMemoryRawMnemonicsStorage not found on get. id=\(id)")
            throw .notFound()
        }
        return value
    }

    func getAll() throws(MnemonicsRepositoryV2GetFailure) -> [CoreMnemonicIdentifier: RawMnemonicsData] {
        store
    }

    func delete(id: CoreMnemonicIdentifier) throws(MnemonicsRepositoryV2DeleteFailure) {
        guard store.removeValue(forKey: id) != nil else {
            logger.e("InMemoryRawMnemonicsStorage not found on delete. id=\(id)")
            throw .notFound()
        }
    }

    func deleteAll() throws(MnemonicsRepositoryV2DeleteFailure) {
        guard !store.isEmpty else {
            logger.e("InMemoryRawMnemonicsStorage not found on deleteAll")
            throw .notFound()
        }
        store.removeAll()
    }
}
