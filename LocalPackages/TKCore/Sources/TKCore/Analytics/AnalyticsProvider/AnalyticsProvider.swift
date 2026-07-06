import Aptabase
import Foundation

public enum EventKey: String {
    case clickDapp = "click_dapp"
    case importWallet = "import_wallet"
    case importWatchOnly = "import_watch_only"
    case generateWallet = "generate_wallet"
    case deleteWallet = "delete_wallet"
    case resetWallet = "reset_wallet"
    case openBrowser = "browser_open"
    case dappSharingCopy = "dapp_sharing_copy"

    case storyOpen = "story_open"
    case storyPageView = "story_page_view"
    case storyClick = "story_click"

    case onrampOpen = "onramp_open"
    case onrampClick = "onramp_click"

    public var parameters: [String: Any] {
        [:]
    }

    public var key: String {
        rawValue
    }
}

public struct AnalyticsEventLegacy {
    public let name: String
    public let params: [String: Any]
}

public protocol AnalyticsService {
    func logEvent(name: String, args: [String: Any])
}

public struct AnalyticsProvider {
    private let services: [AnalyticsService]
    private let firebaseService: FirebaseAnalyticsService
    private let uniqueIdProvider: UniqueIdProvider
    private let appInfoProvider: AppInfoProvider
    private let storeCountryCodeCache: StoreCountryCodeCache

    public init(
        analyticsServices: [AnalyticsService],
        uniqueIdProvider: UniqueIdProvider,
        appInfoProvider: AppInfoProvider
    ) {
        self.services = analyticsServices
        self.firebaseService = FirebaseAnalyticsService()
        self.uniqueIdProvider = uniqueIdProvider
        self.appInfoProvider = appInfoProvider
        self.storeCountryCodeCache = StoreCountryCodeCache(appInfoProvider: appInfoProvider)
    }

    public func log(_ event: Encodable, featureFlags: String? = nil) {
        guard var dict = event.asDictionary() else {
            return
        }

        guard let name = dict.removeValue(forKey: "eventName") as? String else {
            return
        }

        self.log(name: name, args: dict, featureFlags: featureFlags)
    }

    public func log(eventKey: EventKey, args: [String: Any] = [:]) {
        self.log(name: eventKey.key, args: args)
    }

    public func log(event: AnalyticsEventLegacy) {
        self.log(name: event.name, args: event.params)
    }

    private func log(
        name: String,
        args: [String: Any] = [:],
        featureFlags: String? = nil
    ) {
        let baseEvent = AnalyticsEventMobileNative(
            firebaseUserId: uniqueIdProvider.uniqueDeviceId.uuidString,
            platform: .iosNative,
            storeCountryCode: storeCountryCodeCache.value,
            deviceCountryCode: appInfoProvider.deviceCountryCode?.uppercased(),
            featureFlags: featureFlags
        )
        log(name: name, args: args, baseEvent: baseEvent)
    }

    private func log(
        name: String,
        args: [String: Any],
        baseEvent: AnalyticsEventMobileNative
    ) {
        let baseParameters = baseEvent.asDictionary() ?? [:]
        let allParameters = args.reduce(into: baseParameters) { result, element in
            result[element.key] = element.value
        }
        for service in services {
            service.logEvent(name: name, args: allParameters)
        }
    }

    public enum ClickDappEventFrom: String {
        case banner
        case browser
        case browserConnected = "browser_connected"
    }

    public func logClickDappEvent(
        name: String,
        url: String,
        from: ClickDappEventFrom
    ) {
        log(
            eventKey: .clickDapp,
            args: [
                "name": name,
                "url": url,
                "from": from.rawValue,
            ]
        )
    }

    public func logSwapCompleted() {
        logFirebase(name: "swap_completed")
    }

    public func logStakeCompleted() {
        logFirebase(name: "stake_completed")
    }

    public func logSeedBackupConfirmed() {
        logFirebase(name: "seed_backup_confirmed")
    }

    public func logBatteryCharged() {
        logFirebase(name: "battery_charged")
    }

    public func logDepositCompleted() {
        logFirebase(name: "deposit_completed")
    }

    private func logFirebase(name: String) {
        firebaseService.logEvent(name: name, args: [:])
    }
}

// MARK: - Native Swap Events

public extension AnalyticsEventLegacy {
    enum NativeSwap {
        public static func open() -> AnalyticsEventLegacy {
            .init(name: "swap_open", params: ["type": "native"])
        }

        public static func click(from: String, to: String) -> AnalyticsEventLegacy {
            .init(name: "swap_click", params: [
                "jetton_symbol_from": from,
                "jetton_symbol_to": to,
                "type": "native",
            ])
        }

        public static func confirm(from: String, to: String, feeProvider: String) -> AnalyticsEventLegacy {
            .init(name: "swap_confirm", params: [
                "fee_paid_in": feeProvider,
                "jetton_symbol_from": from,
                "jetton_symbol_to": to,
                "provider_name": "ston.fi",
                "type": "native",
            ])
        }

        public static func failed(from: String, to: String, feeProvider: String, error: Error) -> AnalyticsEventLegacy {
            .init(name: "swap_failed", params: [
                "error_message": error.localizedDescription,
                "fee_paid_in": feeProvider,
                "jetton_symbol_from": from,
                "jetton_symbol_to": to,
                "provider_name": "ston.fi",
                "type": "native",
            ])
        }

        public static func success(from: String, to: String, feeProvider: String) -> AnalyticsEventLegacy {
            .init(name: "swap_success", params: [
                "fee_paid_in": feeProvider,
                "jetton_symbol_from": from,
                "jetton_symbol_to": to,
                "provider_name": "ston.fi",
                "type": "native",
            ])
        }
    }
}

private final class StoreCountryCodeCache: @unchecked Sendable {
    private let lock = NSLock()
    private var cached: String?

    var value: String? {
        lock.lock()
        defer { lock.unlock() }
        return cached
    }

    init(appInfoProvider: AppInfoProvider) {
        Task { [weak self] in
            let code = await appInfoProvider.storeCountryCode?.uppercased()
            self?.store(code)
        }
    }

    private func store(_ code: String?) {
        lock.lock()
        defer { lock.unlock() }
        cached = code
    }
}

private extension Encodable {
    func asDictionary() -> [String: Any]? {
        do {
            let data = try JSONEncoder().encode(self)
            let jsonObject = try JSONSerialization.jsonObject(
                with: data,
                options: .allowFragments
            )
            guard let dict = jsonObject as? [String: Any] else {
                return nil
            }
            return dict
        } catch {
            return nil
        }
    }
}
