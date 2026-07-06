import CryptoKit
import Foundation
import LocalAuthentication
import Security
import TKLogging

public struct PasscodeStorage {
    public enum Error: Swift.Error {
        case notFound
        case alreadyExists
        case unexpectedStatus(OSStatus)
        case invalidData
        case invalidPasscode
    }

    public enum ChangePasscodeError: Swift.Error {
        case invalidPasscode
        case other(Error)
    }

    private let seedProvider: () -> String

    public init(seedProvider: @escaping () -> String) {
        self.seedProvider = seedProvider
    }
}

// MARK: - Public API

public extension PasscodeStorage {
    func setPasscode(_ passcode: String) throws(Error) {
        try savePasscode(passcode: passcode)
    }

    func hasPasscode() -> Bool {
        let hasEncryptedPasscode = keychainItemExists(
            query: keychainQuery(
                for: .checkEncryptedPasscode
            ) as CFDictionary
        )
        guard hasEncryptedPasscode else {
            return false
        }
        return wrapKeyExists()
    }

    func deletePasscode() throws(Error) {
        let encryptedPasscodeDeleteStatus = SecItemDelete(
            keychainQuery(
                for: .removeEncryptedPasscode
            ) as CFDictionary
        )
        let wrapKeyDeleteStatus = SecItemDelete(
            keychainQuery(
                for: .removeWrapKey
            ) as CFDictionary
        )
        guard encryptedPasscodeDeleteStatus == errSecSuccess || encryptedPasscodeDeleteStatus == errSecItemNotFound else {
            let failure = KeychainFailure.failure(code: encryptedPasscodeDeleteStatus)
            Log.e("🪵 encrypted passcode delete failed: \(failure)")
            throw .unexpectedStatus(encryptedPasscodeDeleteStatus)
        }
        guard wrapKeyDeleteStatus == errSecSuccess || wrapKeyDeleteStatus == errSecItemNotFound else {
            let failure = KeychainFailure.failure(code: wrapKeyDeleteStatus)
            Log.e("🪵 passcode wrap key delete failed: \(failure)")
            throw .unexpectedStatus(wrapKeyDeleteStatus)
        }
    }

    func getPasscode() throws(Error) -> String {
        let encryptedPayload = try encryptedPasscodePayload()

        let context = LAContext()
        let wrapKey = try readWrapKey(context: context)

        let decryptedPasscodeData = try decryptPasscodeData(
            encryptedPayload,
            with: wrapKey
        )
        guard let passcode = String(data: decryptedPasscodeData, encoding: .utf8) else {
            throw .invalidData
        }
        return passcode
    }
}

// MARK: - Internal

private extension PasscodeStorage {
    private func savePasscode(passcode: String) throws(Error) {
        guard !hasPasscode() else {
            throw .alreadyExists
        }

        let wrapKey = try randomBytes(count: Self.wrapKeyLength)
        let encryptedPayload = try encryptPasscode(
            passcode,
            with: wrapKey
        )
        let accessControl = try createWrapKeyAccessControl()

        let wrapKeyAddStatus = SecItemAdd(
            keychainQuery(
                for: .addWrapKey(
                    value: wrapKey,
                    accessControl: accessControl
                )
            ) as CFDictionary,
            nil
        )
        switch wrapKeyAddStatus {
        case errSecDuplicateItem:
            try overwriteWrapKey(with: wrapKey)
        case errSecSuccess:
            break
        default:
            let failure = KeychainFailure.failure(code: wrapKeyAddStatus)
            Log.e("🪵 wrap key save failed: \(failure)")
            throw .unexpectedStatus(wrapKeyAddStatus)
        }

        let passcodeAddStatus = SecItemAdd(
            keychainQuery(
                for: .addEncryptedPasscode(value: encryptedPayload)
            ) as CFDictionary,
            nil
        )
        switch passcodeAddStatus {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            return try overwriteEncryptedPasscode(with: encryptedPayload)
        default:
            deleteWrapKeyIgnoringErrors()
            let failure = KeychainFailure.failure(code: passcodeAddStatus)
            Log.e("🪵 encrypted passcode save failed: \(failure)")
            throw .unexpectedStatus(passcodeAddStatus)
        }
    }

    private func overwriteWrapKey(with wrapKey: Data) throws(Error) {
        let status = SecItemUpdate(
            keychainQuery(
                for: .removeWrapKey
            ) as CFDictionary,
            [
                kSecValueData: wrapKey as AnyObject,
            ] as CFDictionary
        )
        guard status == errSecSuccess else {
            let failure = KeychainFailure.failure(code: status)
            Log.e("🪵 wrap key overwrite failed: \(failure)")
            throw .unexpectedStatus(status)
        }
    }

    private func overwriteEncryptedPasscode(with payload: Data) throws(Error) {
        let status = SecItemUpdate(
            keychainQuery(
                for: .removeEncryptedPasscode
            ) as CFDictionary,
            [
                kSecValueData: payload as AnyObject,
            ] as CFDictionary
        )
        guard status == errSecSuccess else {
            let failure = KeychainFailure.failure(code: status)
            Log.e("🪵 encrypted passcode overwrite failed: \(failure)")
            throw .unexpectedStatus(status)
        }
    }

    private func encryptedPasscodePayload() throws(Error) -> Data {
        let query = keychainQuery(
            for: .getEncryptedPasscode
        ) as CFDictionary
        var item: AnyObject?
        let status = SecItemCopyMatching(query, &item)

        guard status != errSecItemNotFound else {
            throw .notFound
        }
        guard status == errSecSuccess else {
            throw .unexpectedStatus(status)
        }
        guard let data = item as? Data else {
            throw .invalidData
        }
        return data
    }

    private func readWrapKey(context: LAContext) throws(Error) -> Data {
        let query = keychainQuery(
            for: .getWrapKey(context: context)
        ) as CFDictionary
        var item: AnyObject?
        let status = SecItemCopyMatching(query, &item)

        guard status != errSecItemNotFound else {
            throw .notFound
        }
        guard status == errSecSuccess else {
            throw .unexpectedStatus(status)
        }
        guard let data = item as? Data else {
            throw .invalidData
        }
        return data
    }

    private func keychainItemExists(
        query: CFDictionary
    ) -> Bool {
        let status = SecItemCopyMatching(query, nil)
        switch status {
        case errSecSuccess:
            return true
        case errSecItemNotFound:
            return false
        default:
            let failure = KeychainFailure.failure(code: status)
            Log.e("🪵 keychain item check failed: \(failure)")
            return false
        }
    }

    private func wrapKeyExists() -> Bool {
        let context = LAContext()
        context.interactionNotAllowed = true
        let query = keychainQuery(
            for: .checkWrapKey(context: context)
        ) as CFDictionary
        let status = SecItemCopyMatching(query, nil)
        switch status {
        case errSecSuccess, errSecInteractionNotAllowed:
            return true
        case errSecItemNotFound:
            return false
        default:
            let failure = KeychainFailure.failure(code: status)
            Log.e("🪵 wrap key existence check failed: \(failure)")
            return false
        }
    }

    private func deleteWrapKeyIgnoringErrors() {
        let status = SecItemDelete(
            keychainQuery(
                for: .removeWrapKey
            ) as CFDictionary
        )
        guard status == errSecSuccess || status == errSecItemNotFound else {
            let failure = KeychainFailure.failure(code: status)
            Log.e("🪵 wrap key cleanup failed: \(failure)")
            return
        }
    }

    private func createWrapKeyAccessControl() throws(Error) -> SecAccessControl {
        var error: Unmanaged<CFError>?
        guard let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryAny,
            &error
        ) else {
            throw .unexpectedStatus(osStatus(from: error))
        }
        return accessControl
    }

    private func encryptPasscode(
        _ passcode: String,
        with wrapKey: Data
    ) throws(Error) -> Data {
        let passcodeData = Data(passcode.utf8)
        let key = SymmetricKey(data: wrapKey)
        let sealedBox: AES.GCM.SealedBox
        do {
            sealedBox = try AES.GCM.seal(passcodeData, using: key)
        } catch {
            throw .unexpectedStatus(errSecInternalComponent)
        }
        guard let combined = sealedBox.combined else {
            throw .invalidData
        }
        var payload = Data([Self.passcodePayloadVersion])
        payload.append(combined)
        return payload
    }

    private func decryptPasscodeData(
        _ payload: Data,
        with wrapKey: Data
    ) throws(Error) -> Data {
        guard let version = payload.first, version == Self.passcodePayloadVersion else {
            throw .invalidData
        }
        let combined = payload.dropFirst()
        guard !combined.isEmpty else {
            throw .invalidData
        }

        let key = SymmetricKey(data: wrapKey)
        let sealedBox: AES.GCM.SealedBox
        do {
            sealedBox = try AES.GCM.SealedBox(combined: combined)
        } catch {
            throw .invalidData
        }
        do {
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw .invalidPasscode
        }
    }

    private func randomBytes(count: Int) throws(Error) -> Data {
        var data = Data(repeating: 0, count: count)
        let status = data.withUnsafeMutableBytes { buffer in
            SecRandomCopyBytes(
                kSecRandomDefault,
                count,
                buffer.baseAddress!
            )
        }
        guard status == errSecSuccess else {
            throw .unexpectedStatus(status)
        }
        return data
    }

    private func osStatus(
        from error: Unmanaged<CFError>?
    ) -> OSStatus {
        guard let error else {
            return errSecInternalComponent
        }
        let cfError = error.takeRetainedValue()
        return OSStatus(CFErrorGetCode(cfError))
    }
}

// MARK: - Keychain helpers

extension PasscodeStorage {
    enum KeychainFailure: Swift.Error {
        case failure(code: OSStatus)
    }

    enum KeychainQueryType {
        case checkEncryptedPasscode
        case addEncryptedPasscode(value: Data)
        case getEncryptedPasscode
        case removeEncryptedPasscode
        case checkWrapKey(context: LAContext)
        case addWrapKey(
            value: Data,
            accessControl: SecAccessControl
        )
        case getWrapKey(context: LAContext)
        case removeWrapKey
    }

    private func keychainQuery(
        for type: KeychainQueryType
    ) -> [CFString: Any] {
        let service = serviceKey

        switch type {
        case .checkEncryptedPasscode:
            return [
                kSecClass: securityClass,
                kSecAttrService: service,
                kSecAttrAccount: Keys.encryptedPasscodeAccountKey,
                kSecMatchLimit: kSecMatchLimitOne,
                kSecReturnAttributes: true as AnyObject,
            ]
        case let .addEncryptedPasscode(value):
            return [
                kSecClass: securityClass,
                kSecAttrAccessible: keychainWriteAccessType,
                kSecAttrService: service,
                kSecAttrAccount: Keys.encryptedPasscodeAccountKey,
                kSecValueData: value as AnyObject,
            ]
        case .getEncryptedPasscode:
            return [
                kSecClass: securityClass,
                kSecAttrService: service,
                kSecAttrAccount: Keys.encryptedPasscodeAccountKey,
                kSecMatchLimit: kSecMatchLimitOne,
                kSecReturnData: true as AnyObject,
            ]
        case .removeEncryptedPasscode:
            return [
                kSecClass: securityClass,
                kSecAttrAccessible: keychainWriteAccessType,
                kSecAttrService: service,
                kSecAttrAccount: Keys.encryptedPasscodeAccountKey,
            ]
        case let .checkWrapKey(context):
            return [
                kSecClass: securityClass,
                kSecAttrService: service,
                kSecAttrAccount: Keys.wrapKeyAccountKey,
                kSecMatchLimit: kSecMatchLimitOne,
                kSecReturnAttributes: true as AnyObject,
                kSecUseAuthenticationContext: context,
            ]
        case let .addWrapKey(value, accessControl):
            return [
                kSecClass: securityClass,
                kSecAttrService: service,
                kSecAttrAccount: Keys.wrapKeyAccountKey,
                kSecAttrAccessControl: accessControl,
                kSecValueData: value as AnyObject,
            ]
        case let .getWrapKey(context):
            return [
                kSecClass: securityClass,
                kSecAttrService: service,
                kSecAttrAccount: Keys.wrapKeyAccountKey,
                kSecMatchLimit: kSecMatchLimitOne,
                kSecReturnData: true as AnyObject,
                kSecUseAuthenticationContext: context,
            ]
        case .removeWrapKey:
            return [
                kSecClass: securityClass,
                kSecAttrService: service,
                kSecAttrAccount: Keys.wrapKeyAccountKey,
            ]
        }
    }

    private var keychainWriteAccessType: Any {
        kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    }

    private var securityClass: Any {
        kSecClassGenericPassword
    }

    private var serviceKey: String {
        "v2pwd\(seedProvider())"
    }

    private static var passcodePayloadVersion: UInt8 {
        1
    }

    private static var wrapKeyLength: Int {
        32
    }
}

private enum Keys {
    static let encryptedPasscodeAccountKey = "PasscodeEncrypted"
    static let wrapKeyAccountKey = "PasscodeWrapKey"
}
