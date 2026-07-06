import Foundation
import KeeperCoreComponents
import TKCryptoKit
import TonSwift
import TronSwift

public enum TonTron {
    public static func tonMnemonicToTronMnemonic(
        _ tonMnemonic: [String],
        useBip39DerivationForBip39Mnemonics: Bool
    ) -> [String] {
        if shouldUseDirectBip39Derivation(
            mnemonicWords: tonMnemonic,
            useBip39DerivationForBip39Mnemonics: useBip39DerivationForBip39Mnemonics
        ) {
            return tonMnemonic
        }
        let entropy = TonSwift.Mnemonic.mnemonicToEntropy(mnemonicArray: tonMnemonic)
        let patchedEntropy = patchTonEntropy(entropy: entropy)
        return TronSwift.Mnemonic.entropyToMnemonic(entropy: patchedEntropy)
    }

    public static func derivedKeyPair(
        tonMnemonic: [String],
        index: Int,
        useBip39DerivationForBip39Mnemonics: Bool
    ) throws -> TronSwift.KeyPair {
        let tronMnemonic = tonMnemonicToTronMnemonic(
            tonMnemonic,
            useBip39DerivationForBip39Mnemonics: useBip39DerivationForBip39Mnemonics
        )
        return try HDKeys.derivedKeyPair(
            mnemonic: tronMnemonic,
            purpose: 44,
            coin: 195,
            account: 0,
            chain: 0,
            index: index,
            derivationCurve: Secp256k1DerivationCurve()
        )
    }

    private static func patchTonEntropy(entropy: Data) -> Data {
        let rangeUpper = (Constants.mnemonicsWordNumber * 11 - Constants.checksumBits) / 8
        return HMAC.sha256(message: entropy, key: Constants.networkLabel.data(using: .utf8)!)[0 ..< rangeUpper]
    }

    private static func shouldUseDirectBip39Derivation(
        mnemonicWords: [String],
        useBip39DerivationForBip39Mnemonics: Bool
    ) -> Bool {
        guard useBip39DerivationForBip39Mnemonics else {
            return false
        }
        guard !TonSwift.Mnemonic.mnemonicValidate(mnemonicArray: mnemonicWords) else {
            return false
        }
        return BIP39Mnemonic.isValidBip39SoftMnemonic(mnemonicArray: mnemonicWords)
    }

    private enum Constants {
        static let networkLabel = "trx-0x2b6653dc_root"
        static let mnemonicsWordNumber = 12
        static let checksumBits = 4
    }
}

public extension TonTron {
    static func resolvedUseBip39DerivationForWalletTron(
        tonMnemonic: [String],
        walletTron: WalletTron?,
        defaultUseBip39DerivationForBip39Mnemonics: Bool
    ) throws -> Bool {
        guard let walletTron else {
            return defaultUseBip39DerivationForBip39Mnemonics
        }

        let legacyKeyPair = try derivedKeyPair(
            tonMnemonic: tonMnemonic,
            index: 0,
            useBip39DerivationForBip39Mnemonics: false
        )
        if legacyKeyPair.publicKey.data == walletTron.publicKey.data {
            return false
        }

        let bip39KeyPair = try derivedKeyPair(
            tonMnemonic: tonMnemonic,
            index: 0,
            useBip39DerivationForBip39Mnemonics: true
        )
        if bip39KeyPair.publicKey.data == walletTron.publicKey.data {
            return true
        }

        return defaultUseBip39DerivationForBip39Mnemonics
    }

    static func derivedKeyPair(
        tonMnemonic: [String],
        index: Int,
        walletTron: WalletTron?,
        defaultUseBip39DerivationForBip39Mnemonics: Bool
    ) throws -> TronSwift.KeyPair {
        let useBip39DerivationForBip39Mnemonics = try resolvedUseBip39DerivationForWalletTron(
            tonMnemonic: tonMnemonic,
            walletTron: walletTron,
            defaultUseBip39DerivationForBip39Mnemonics: defaultUseBip39DerivationForBip39Mnemonics
        )

        return try derivedKeyPair(
            tonMnemonic: tonMnemonic,
            index: index,
            useBip39DerivationForBip39Mnemonics: useBip39DerivationForBip39Mnemonics
        )
    }
}
