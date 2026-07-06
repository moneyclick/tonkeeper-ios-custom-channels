@testable import KeeperCore
import TronSwift
import XCTest

final class TonTronBip39ImportTests: XCTestCase {
    func test_tronAddressDerivation_matchesKnownIosValues_whenFlagDisabled() throws {
        for testCase in testCases {
            let address = try deriveAddress(
                mnemonic: testCase.mnemonic,
                useBip39DerivationForBip39Mnemonics: false
            )
            XCTAssertEqual(address.base58, testCase.expectedAddressWhenFlagDisabled, testCase.name)
        }
    }

    func test_tronAddressDerivation_matchesKnownIosValues_whenFlagEnabled() throws {
        for testCase in testCases {
            let address = try deriveAddress(
                mnemonic: testCase.mnemonic,
                useBip39DerivationForBip39Mnemonics: true
            )
            XCTAssertEqual(address.base58, testCase.expectedAddressWhenFlagEnabled, testCase.name)
        }
    }

    func test_resolvedUseBip39DerivationForWalletTron_prefersStoredLegacyWalletOverDefaultFlag() throws {
        let mnemonic = testCases[0].mnemonic
        let walletTron = try makeWalletTron(
            mnemonic: mnemonic,
            useBip39DerivationForBip39Mnemonics: false
        )

        let resolved = try TonTron.resolvedUseBip39DerivationForWalletTron(
            tonMnemonic: mnemonic,
            walletTron: walletTron,
            defaultUseBip39DerivationForBip39Mnemonics: true
        )

        XCTAssertFalse(resolved)
    }

    func test_resolvedUseBip39DerivationForWalletTron_prefersStoredBip39WalletOverDefaultFlag() throws {
        let mnemonic = testCases[0].mnemonic
        let walletTron = try makeWalletTron(
            mnemonic: mnemonic,
            useBip39DerivationForBip39Mnemonics: true
        )

        let resolved = try TonTron.resolvedUseBip39DerivationForWalletTron(
            tonMnemonic: mnemonic,
            walletTron: walletTron,
            defaultUseBip39DerivationForBip39Mnemonics: false
        )

        XCTAssertTrue(resolved)
    }

    private func deriveAddress(
        mnemonic: [String],
        useBip39DerivationForBip39Mnemonics: Bool
    ) throws -> TronSwift.Address {
        let keyPair = try TonTron.derivedKeyPair(
            tonMnemonic: mnemonic,
            index: 0,
            useBip39DerivationForBip39Mnemonics: useBip39DerivationForBip39Mnemonics
        )
        return try TronSwift.Address(publicKey: keyPair.publicKey)
    }

    private func makeWalletTron(
        mnemonic: [String],
        useBip39DerivationForBip39Mnemonics: Bool
    ) throws -> WalletTron {
        let keyPair = try TonTron.derivedKeyPair(
            tonMnemonic: mnemonic,
            index: 0,
            useBip39DerivationForBip39Mnemonics: useBip39DerivationForBip39Mnemonics
        )
        return try WalletTron(
            publicKey: keyPair.publicKey,
            address: TronSwift.Address(publicKey: keyPair.publicKey),
            isOn: true
        )
    }

    private let testCases: [TonTronTestCase] = [
        .init(
            name: "12 words bip39 from TronLink",
            mnemonic: [
                "vanish", "grab", "filter", "unique", "night", "picnic",
                "door", "carpet", "drastic", "artwork", "pioneer", "merry",
            ],
            expectedAddressWhenFlagDisabled: "TSz4eJZnjoZiQFgT7fxFVNAFoxoY3Hf4aq",
            expectedAddressWhenFlagEnabled: "TU1r33n75FL5dShBt13xcJfgBLuahLgTZo"
        ),
        .init(
            name: "12 words bip39 from Tonkeeper",
            mnemonic: [
                "web", "happy", "wedding", "sell", "trophy", "legal",
                "stand", "ordinary", "quantum", "arrange", "until", "add",
            ],
            expectedAddressWhenFlagDisabled: "THASugP3gCifGsSRm3CXojjQoSv2aiuPz8",
            expectedAddressWhenFlagEnabled: "TGp4h3nxn39NxxAkjygMX63ydnhS9R69tm"
        ),
        .init(
            name: "24 words bip39 from MTW",
            mnemonic: [
                "chunk", "dinosaur", "wealth", "clean", "case", "duty",
                "kitchen", "number", "bless", "security", "pistol", "add",
                "club", "boat", "phrase", "doctor", "jacket", "scorpion",
                "gas", "cream", "hurt", "weather", "check", "twelve",
            ],
            expectedAddressWhenFlagDisabled: "TQDDJtHMB6o6LRYd4TKwS7FtP6D6p6i5Bh",
            expectedAddressWhenFlagEnabled: "TPobeKoaGgb9mxyXYheh3BXihZSARCppT3"
        ),
        .init(
            name: "24 words edge case: bip39 + ton balance",
            mnemonic: [
                "potato", "kind", "you", "abandon", "curve", "hybrid",
                "approve", "outside", "document", "culture", "edit", "few",
                "fit", "magnet", "tilt", "shrimp", "path", "coil",
                "spin", "always", "robot", "blame", "grace", "beyond",
            ],
            expectedAddressWhenFlagDisabled: "TWcLfzyk3cXEpJAnrtoLYczd16REHLiBU3",
            expectedAddressWhenFlagEnabled: "TWcLfzyk3cXEpJAnrtoLYczd16REHLiBU3"
        ),
        .init(
            name: "24 words edge case: bip39 + ton",
            mnemonic: [
                "water", "filter", "owner", "believe", "resemble", "appear",
                "violin", "dune", "margin", "before", "treat", "zone",
                "click", "bicycle", "soul", "party", "knock", "disease",
                "focus", "art", "today", "fresh", "merry", "swap",
            ],
            expectedAddressWhenFlagDisabled: "TAEhdLUV8pdWTBvE1FzdcxU3g2Cz62zeRQ",
            expectedAddressWhenFlagEnabled: "TAEhdLUV8pdWTBvE1FzdcxU3g2Cz62zeRQ"
        ),
        .init(
            name: "24 words edge case: ton + keychain",
            mnemonic: [
                "assault", "trend", "dish", "hero", "urge", "panel",
                "tornado", "various", "noise", "silly", "leg", "regret",
                "remove", "parrot", "skull", "snap", "slender", "floor",
                "lesson", "person", "capable", "labor", "possible", "forum",
            ],
            expectedAddressWhenFlagDisabled: "TENWCpsrCMsvZEuich1qRUcu8BsESRHrQ2",
            expectedAddressWhenFlagEnabled: "TENWCpsrCMsvZEuich1qRUcu8BsESRHrQ2"
        ),
    ]
}

private struct TonTronTestCase {
    let name: String
    let mnemonic: [String]
    let expectedAddressWhenFlagDisabled: String
    let expectedAddressWhenFlagEnabled: String
}
