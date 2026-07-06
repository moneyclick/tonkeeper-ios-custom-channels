import Foundation

public enum FeatureFlag: CaseIterable, Hashable {
    case inAppReviewEnabled
    case walletKitEnabled
    case multichainEnabled
    case streamingApiV2Enabled
    case tronBip39ImportFix
    case tradingUiEnabled
    case mnemonicsStorageV2
}

public extension FeatureFlag {
    var localKey: String {
        switch self {
        case .inAppReviewEnabled:
            "inAppReviewEnabled"
        case .walletKitEnabled:
            "walletKitEnabled"
        case .multichainEnabled:
            "multichainEnabled"
        case .streamingApiV2Enabled:
            "streamingApiV2Enabled"
        case .tronBip39ImportFix:
            "tronBip39ImportFix"
        case .tradingUiEnabled:
            "tradingUiEnabled"
        case .mnemonicsStorageV2:
            "mnemonicsStorageV2"
        }
    }

    var remoteKey: String? {
        switch self {
        case .inAppReviewEnabled:
            "ios_in_app_review_enabled"
        case .walletKitEnabled:
            "ios_wallet_kit_enabled"
        case .multichainEnabled:
            "ios_multichain_enabled"
        case .streamingApiV2Enabled:
            "ios_is_streaming_api_v2_enabled"
        case .tronBip39ImportFix:
            "ios_tron_bip39_import_fix"
        case .tradingUiEnabled:
            "ios_is_trading_ui_enabled"
        case .mnemonicsStorageV2:
            "ios_mnemonic_storage_v2"
        }
    }

    var defaultValue: Bool {
        switch self {
        case .inAppReviewEnabled:
            false
        case .walletKitEnabled:
            false
        case .multichainEnabled:
            false
        case .streamingApiV2Enabled:
            false
        case .tronBip39ImportFix:
            false
        case .tradingUiEnabled:
            false
        case .mnemonicsStorageV2:
            false
        }
    }
}

public struct FeatureFlagValue {
    public var localValue: Bool?
    public var remoteValue: Bool?
    public var defaultValue: Bool
    public var resolvedValue: Bool
}
