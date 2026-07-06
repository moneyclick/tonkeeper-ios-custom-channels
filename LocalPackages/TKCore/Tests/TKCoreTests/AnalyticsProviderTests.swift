import Foundation
@testable import TKCore
import TKKeychain
import XCTest

final class AnalyticsProviderTests: XCTestCase {
    func testLegacyLogEventKeyIncludesAnalyticsEventMobileNativeFields() throws {
        let (provider, service) = makeSubject()
        let eventKey = EventKey.importWallet
        let customKey = "source"
        let customValue = "test"

        provider.log(eventKey: eventKey, args: [customKey: customValue])

        let call = try XCTUnwrap(service.calls.first)

        XCTAssertEqual(call.name, eventKey.key)
        XCTAssertEqual(call.args[customKey] as? String, customValue)
        XCTAssertEqual(
            call.args[AnalyticsEventMobileNative.CodingKeys.schemaVersion.rawValue] as? String,
            AnalyticsEventMobileNative().schemaVersion
        )
        XCTAssertEqual(
            call.args[AnalyticsEventMobileNative.CodingKeys.firebaseUserId.rawValue] as? String,
            TestData.uniqueDeviceId.uuidString
        )
        XCTAssertEqual(
            call.args[AnalyticsEventMobileNative.CodingKeys.platform.rawValue] as? String,
            AnalyticsEventMobileNative.Platform.iosNative.rawValue
        )
    }

    func testLegacyLogEventKeyPrefersArgsWhenTheyConflictWithAnalyticsEventMobileNative() throws {
        let (provider, service) = makeSubject()
        let schemaVersion = AnalyticsEventMobileNative.CodingKeys.schemaVersion.rawValue
        let firebaseUserId = AnalyticsEventMobileNative.CodingKeys.firebaseUserId.rawValue
        let platform = AnalyticsEventMobileNative.CodingKeys.platform.rawValue

        provider.log(
            eventKey: .importWallet,
            args: [
                schemaVersion: "override",
                firebaseUserId: "external-id",
            ]
        )

        let call = try XCTUnwrap(service.calls.first)

        XCTAssertEqual(call.args[schemaVersion] as? String, "override")
        XCTAssertEqual(call.args[firebaseUserId] as? String, "external-id")
        XCTAssertEqual(
            call.args[platform] as? String,
            AnalyticsEventMobileNative.Platform.iosNative.rawValue
        )
    }

    func testLogEventKeyPrefersArgsWhenTheyConflictWithAnalyticsEventMobileNative() throws {
        let (provider, service) = makeSubject()
        let schemaVersion = AnalyticsEventMobileNative.CodingKeys.schemaVersion.rawValue
        let firebaseUserId = AnalyticsEventMobileNative.CodingKeys.firebaseUserId.rawValue
        let platform = AnalyticsEventMobileNative.CodingKeys.platform.rawValue

        provider.log(
            SendOpen(from: .deepLink)
                .withExtraValues(
                    [
                        schemaVersion: "override",
                        firebaseUserId: "external-id",
                    ]
                )
        )

        let call = try XCTUnwrap(service.calls.first)

        XCTAssertEqual(call.args[schemaVersion] as? String, "override")
        XCTAssertEqual(call.args[firebaseUserId] as? String, "external-id")
        XCTAssertEqual(
            call.args[platform] as? String,
            AnalyticsEventMobileNative.Platform.iosNative.rawValue
        )
    }

    func testLogEncodableWithFeatureFlagsIncludesThemOnBaseEvent() throws {
        let (provider, service) = makeSubject()

        let featureFlags = #"{"alpha":"","beta":"42"}"#

        provider.log(LaunchApp(), featureFlags: featureFlags)

        let call = try XCTUnwrap(service.calls.first)

        XCTAssertEqual(
            call.args[AnalyticsEventMobileNative.CodingKeys.featureFlags.rawValue] as? String,
            featureFlags
        )
    }

    func testLogEncodableIncludesAnalyticsEventMobileNativeFields() throws {
        let (provider, service) = makeSubject()

        let event = CustomError(
            severity: .warning,
            errorMessage: "tron_broken_address_detected"
        )

        provider.log(event)

        let call = try XCTUnwrap(service.calls.first)

        XCTAssertEqual(call.name, event.eventName)
        XCTAssertEqual(call.args[CustomError.CodingKeys.errorMessage.rawValue] as? String, event.errorMessage)
        XCTAssertEqual(
            call.args[AnalyticsEventMobileNative.CodingKeys.schemaVersion.rawValue] as? String,
            AnalyticsEventMobileNative().schemaVersion
        )
        XCTAssertEqual(
            call.args[AnalyticsEventMobileNative.CodingKeys.firebaseUserId.rawValue] as? String,
            TestData.uniqueDeviceId.uuidString
        )
        XCTAssertEqual(
            call.args[AnalyticsEventMobileNative.CodingKeys.platform.rawValue] as? String,
            AnalyticsEventMobileNative.Platform.iosNative.rawValue
        )
    }

    func testLogPrefillsUppercasedDeviceCountryCode() throws {
        let (provider, service) = makeSubject(deviceCountryCode: "us")

        provider.log(LaunchApp())

        let call = try XCTUnwrap(service.calls.first)

        XCTAssertEqual(
            call.args[AnalyticsEventMobileNative.CodingKeys.deviceCountryCode.rawValue] as? String,
            "US"
        )
    }
}

private extension AnalyticsProviderTests {
    func makeSubject(
        deviceCountryCode: String? = nil
    ) -> (AnalyticsProvider, AnalyticsServiceSpy) {
        let service = AnalyticsServiceSpy()
        let userDefaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
        let uniqueIdProvider = UniqueIdProvider(
            userDefaults: userDefaults,
            keychainVault: KeychainVaultMock(
                storedUUID: TestData.uniqueDeviceId
            )
        )

        let appInfoProvider = AppInfoProvider(userDefaults: userDefaults)
        if let deviceCountryCode {
            appInfoProvider.overrideDeviceCountryCode(deviceCountryCode)
        }

        let provider = AnalyticsProvider(
            analyticsServices: [service],
            uniqueIdProvider: uniqueIdProvider,
            appInfoProvider: appInfoProvider
        )

        return (provider, service)
    }
}

private enum TestData {
    static let uniqueDeviceId = UUID(uuidString: "00000000-0000-0000-0000-000000000123")!
}

private final class AnalyticsServiceSpy: AnalyticsService {
    private(set) var calls = [(name: String, args: [String: Any])]()

    func logEvent(name: String, args: [String: Any]) {
        calls.append((name: name, args: args))
    }
}

private final class KeychainVaultMock: TKKeychainVault {
    private var storedData: Data?

    init(storedUUID: UUID) {
        storedData = try? JSONEncoder().encode(storedUUID)
    }

    func get(query: TKKeychainQuery) throws -> Data {
        guard let storedData else {
            throw TKKeychainVaultError.unexpectedData
        }

        return storedData
    }

    func get(query: TKKeychainQuery) throws -> String {
        guard let storedData,
              let string = String(data: storedData, encoding: .utf8)
        else {
            throw TKKeychainVaultError.unexpectedData
        }

        return string
    }

    func get<T: Codable>(query: TKKeychainQuery) throws -> T {
        guard let storedData else {
            throw TKKeychainVaultError.unexpectedData
        }

        return try JSONDecoder().decode(T.self, from: storedData)
    }

    func set(_ value: Data, query: TKKeychainQuery) throws {
        storedData = value
    }

    func set(_ value: String, query: TKKeychainQuery) throws {
        storedData = value.data(using: .utf8)
    }

    func set<T: Codable>(_ value: T, query: TKKeychainQuery) throws {
        storedData = try JSONEncoder().encode(value)
    }

    func delete(_ query: TKKeychainQuery) throws {
        storedData = nil
    }
}
