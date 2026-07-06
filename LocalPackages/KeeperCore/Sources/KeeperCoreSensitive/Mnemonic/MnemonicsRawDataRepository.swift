//
//  MnemonicsRawDataRepository.swift
//  WalletCore
//
//  Created by rzmn on 09.02.2026.
//

import Foundation
import TKLogging

public struct MnemonicsRawDataRepository<MnemonicItem: Codable> {
    private let seedProvider: () -> String
    private let logger = LogDomain.mnemonicStorage

    public init(seedProvider: @escaping () -> String) {
        self.seedProvider = seedProvider
    }
}

extension MnemonicsRawDataRepository {
    enum InternalDecodingFailure: Error {
        case wrongValueType(String)
    }
}

extension MnemonicsRawDataRepository: RawMnemonicsDataRepositoryV2 where MnemonicItem == RawMnemonicsData {}

extension MnemonicsRawDataRepository: MnemonicsRepositoryV2 {
    public func hasMnemonic() throws(MnemonicsRepositoryHasAnyFailure) -> Bool {
        let query = keychainQuery(
            for: .checkHasMnemonics
        ) as CFDictionary
        let status = SecItemCopyMatching(query, nil)
        switch status {
        case errSecSuccess:
            return true
        case errSecItemNotFound:
            return false
        default:
            logger.e("Failed to check v2 mnemonics presence. status=\(status)")
            throw .reading(
                KeychainFailure.failure(code: status)
            )
        }
    }

    public func add(
        _ mnemonic: MnemonicItem,
        id: CoreMnemonicIdentifier
    ) throws(MnemonicsRepositoryV2SaveFailure) {
        let data: Data
        do {
            data = try JSONEncoder().encode(mnemonic)
        } catch {
            logger.e("Failed to encode mnemonic for add. id=\(id), type=\(MnemonicItem.self), error=\(error)")
            throw .encoding(error)
        }
        let query = keychainQuery(
            for: .addMnemonic(
                id: id,
                value: data
            )
        ) as CFDictionary
        let status = SecItemAdd(query, nil)
        switch status {
        case errSecDuplicateItem:
            logger.e("Duplicate mnemonic add attempt. id=\(id), status=\(status)")
            throw .dublicate(
                KeychainFailure.failure(code: status)
            )
        case errSecSuccess:
            return
        default:
            logger.e("Failed to add mnemonic to keychain. id=\(id), status=\(status)")
            throw .writing(
                KeychainFailure.failure(code: status)
            )
        }
    }

    public func upsert(
        _ mnemonic: MnemonicItem,
        id: CoreMnemonicIdentifier
    ) throws(MnemonicsRepositoryV2UpsertFailure) {
        let data: Data
        do {
            data = try JSONEncoder().encode(mnemonic)
        } catch {
            logger.e("Failed to encode mnemonic for upsert. id=\(id), type=\(MnemonicItem.self), error=\(error)")
            throw .encoding(error)
        }
        let addQuery = keychainQuery(
            for: .addMnemonic(
                id: id,
                value: data
            )
        ) as CFDictionary
        let status = SecItemAdd(addQuery, nil)
        switch status {
        case errSecDuplicateItem:
            break
        case errSecSuccess:
            return
        default:
            logger.e("Failed to insert mnemonic during upsert. id=\(id), status=\(status)")
            throw .writing(
                KeychainFailure.failure(code: status)
            )
        }
        let updateQuery = keychainQuery(
            for: .updateMnemonic(id: id)
        ) as CFDictionary
        let attributesToUpdate: [CFString: Any] = [
            kSecValueData: data as AnyObject,
        ]
        let updateStatus = SecItemUpdate(
            updateQuery,
            attributesToUpdate as CFDictionary
        )
        switch updateStatus {
        case errSecSuccess:
            return
        default:
            logger.e("Failed to update mnemonic during upsert. id=\(id), status=\(updateStatus)")
            throw .writing(
                KeychainFailure.failure(code: updateStatus)
            )
        }
    }

    public func get(
        id: CoreMnemonicIdentifier
    ) throws(MnemonicsRepositoryV2GetFailure) -> MnemonicItem {
        let query = keychainQuery(
            for: .getMnemonic(id: id)
        ) as CFDictionary
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query, &item)
        switch status {
        case errSecItemNotFound:
            logger.e("Requested mnemonic is not found. id=\(id), status=\(status)")
            throw .notFound(
                KeychainFailure.failure(code: status)
            )
        case errSecSuccess:
            break
        default:
            logger.e("Failed to read mnemonic from keychain. id=\(id), status=\(status)")
            throw .reading(
                KeychainFailure.failure(code: status)
            )
        }
        guard let item else {
            logger.e("Keychain returned empty result for mnemonic. id=\(id)")
            throw .decoding(
                InternalDecodingFailure.wrongValueType("nil")
            )
        }
        guard
            let attributes = item as? [String: Any],
            let data = attributes[kSecValueData as String] as? Data
        else {
            logger.e("Keychain returned unexpected value type for mnemonic. id=\(id), type=\(type(of: item))")
            throw .decoding(
                InternalDecodingFailure.wrongValueType("\(type(of: item))")
            )
        }
        let mnemonic: MnemonicItem
        do {
            mnemonic = try JSONDecoder().decode(MnemonicItem.self, from: data)
        } catch {
            logger.e("Failed to decode mnemonic payload. id=\(id), bytes=\(data.count), error=\(error)")
            throw .decoding(error)
        }
        return mnemonic
    }

    public func getAll() throws(MnemonicsRepositoryV2GetFailure) -> [CoreMnemonicIdentifier: MnemonicItem] {
        let query = keychainQuery(
            for: .getAllMnemonics
        ) as CFDictionary
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query, &result)

        switch status {
        case errSecSuccess:
            break
        default:
            logger.e("Failed to read all mnemonics from keychain. status=\(status)")
            throw .reading(
                KeychainFailure.failure(code: status)
            )
        }
        guard let result else {
            logger.e("Keychain returned empty result for all mnemonics.")
            throw .decoding(
                InternalDecodingFailure.wrongValueType("nil")
            )
        }

        guard let rawValues = result as? [[String: Any]] else {
            logger.e("Keychain returned unexpected value type for all mnemonics. type=\(type(of: result))")
            throw .decoding(
                InternalDecodingFailure.wrongValueType("\(type(of: result))")
            )
        }
        var values: [CoreMnemonicIdentifier: Data] = [:]
        for rawValue in rawValues {
            guard
                let account = rawValue[kSecAttrAccount as String] as? String,
                let data = rawValue[kSecValueData as String] as? Data
            else {
                logger.e("Keychain returned malformed item for all mnemonics. item=\(rawValue)")
                throw .decoding(
                    InternalDecodingFailure.wrongValueType("Malformed keychain dictionary item")
                )
            }
            values[account] = data
        }

        let decoder = JSONDecoder()
        var mnemonics: [CoreMnemonicIdentifier: MnemonicItem] = [:]
        for (account, data) in values {
            do {
                mnemonics[account] = try decoder.decode(MnemonicItem.self, from: data)
            } catch {
                logger.e("Failed to decode mnemonic during getAll. id=\(account), bytes=\(data.count), error=\(error)")
                throw .decoding(error)
            }
        }
        return mnemonics
    }

    public func delete(
        id: CoreMnemonicIdentifier
    ) throws(MnemonicsRepositoryV2DeleteFailure) {
        let query = keychainQuery(
            for: .removeMnemonic(id: id)
        ) as CFDictionary
        let status = SecItemDelete(query)
        switch status {
        case errSecItemNotFound:
            logger.e("Cannot delete mnemonic because it does not exist. id=\(id), status=\(status)")
            throw .notFound(
                KeychainFailure.failure(code: status)
            )
        case errSecSuccess:
            return
        default:
            logger.e("Failed to delete mnemonic from keychain. id=\(id), status=\(status)")
            throw .writing(
                KeychainFailure.failure(code: status)
            )
        }
    }

    public func deleteAll() throws(MnemonicsRepositoryV2DeleteFailure) {
        let query = keychainQuery(
            for: .removeAll
        ) as CFDictionary
        let status = SecItemDelete(query)
        switch status {
        case errSecItemNotFound:
            logger.e("Cannot delete all mnemonics because no entries exist. status=\(status)")
            throw .notFound(
                KeychainFailure.failure(code: status)
            )
        case errSecSuccess:
            return
        default:
            logger.e("Failed to delete all mnemonics from keychain. status=\(status)")
            throw .writing(
                KeychainFailure.failure(code: status)
            )
        }
    }
}

extension MnemonicsRawDataRepository {
    enum KeychainFailure: Error {
        case failure(code: OSStatus)
    }

    enum KeychainQueryType {
        case checkHasMnemonics
        case addMnemonic(
            id: CoreMnemonicIdentifier,
            value: Data
        )
        case updateMnemonic(
            id: CoreMnemonicIdentifier
        )
        case getAllMnemonics
        case getMnemonic(
            id: CoreMnemonicIdentifier
        )
        case removeMnemonic(
            id: CoreMnemonicIdentifier
        )
        case removeAll
    }

    private func keychainQuery(
        for type: KeychainQueryType
    ) -> [CFString: Any] {
        let seed = seedProvider()
        let service = "v2mnemonics_\(seed)"

        switch type {
        case .checkHasMnemonics:
            return [
                kSecClass: securityClass,
                kSecAttrService: service,
                kSecMatchLimit: kSecMatchLimitOne,
                kSecReturnAttributes: true,
            ]
        case let .addMnemonic(id, value):
            return [
                kSecClass: securityClass,
                kSecAttrAccessible: keychainWriteAccessType,
                kSecAttrService: service,
                kSecAttrAccount: id,
                kSecValueData: value as AnyObject,
            ]
        case let .getMnemonic(id):
            return [
                kSecClass: securityClass,
                kSecAttrService: service,
                kSecAttrAccount: id,
                kSecMatchLimit: kSecMatchLimitOne,
                kSecReturnData: true as AnyObject,
                kSecReturnAttributes: true as AnyObject,
            ]
        case .getAllMnemonics:
            return [
                kSecClass: securityClass,
                kSecAttrService: service,
                kSecMatchLimit: kSecMatchLimitAll,
                kSecReturnData: true as AnyObject,
                kSecReturnAttributes: true as AnyObject,
            ]
        case let .removeMnemonic(id), let .updateMnemonic(id):
            return [
                kSecClass: securityClass,
                kSecAttrAccessible: keychainWriteAccessType,
                kSecAttrService: service,
                kSecAttrAccount: id,
            ]
        case .removeAll:
            return [
                kSecClass: securityClass,
                kSecAttrAccessible: keychainWriteAccessType,
                kSecAttrService: service,
            ]
        }
    }

    private var keychainWriteAccessType: Any {
        kSecAttrAccessibleWhenUnlocked
    }

    private var securityClass: Any {
        kSecClassGenericPassword
    }
}
