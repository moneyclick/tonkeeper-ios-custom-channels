import TonSwift

public enum DerivationType: Codable {
    case ton
    case bip39
    case bip39soft
    case unknown
}

public extension DerivationType {
    var isKnown: Bool {
        !isUnknown
    }

    var isUnknown: Bool {
        switch self {
        case .unknown:
            true
        default:
            false
        }
    }
}

public extension DerivationType {
    static func guessByWords(
        _ words: [String]
    ) -> Self {
        if TonSwift.Mnemonic.mnemonicValidate(mnemonicArray: words) {
            return .ton
        }
        if BIP39Mnemonic.isValidBip39Mnemonic(mnemonicArray: words) {
            return .bip39
        }
        if BIP39Mnemonic.isValidBip39SoftMnemonic(mnemonicArray: words) {
            return .bip39soft
        }
        return .unknown
    }
}
