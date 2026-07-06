import CryptoKit
import Foundation
import Sodium
import TonSwift

public enum MnemonicsRepositoryV2SaveFailure: Error {
    case encoding(_ underlying: Error? = nil)
    case writing(_ underlying: Error? = nil)
    case dublicate(_ underlying: Error? = nil)
}

public enum MnemonicsRepositoryV2UpsertFailure: Error {
    case encoding(_ underlying: Error? = nil)
    case writing(_ underlying: Error? = nil)
}

public enum MnemonicsRepositoryV2GetFailure: Error {
    case reading(_ underlying: Error? = nil)
    case decoding(_ underlying: Error? = nil)
    case notFound(_ underlying: Error? = nil)
}

public enum MnemonicsRepositoryV2DeleteFailure: Error {
    case writing(_ underlying: Error? = nil)
    case notFound(_ underlying: Error? = nil)
}

public enum MnemonicsRepositoryHasAnyFailure: Error {
    case reading(_ underlying: Error? = nil)
}

public protocol MnemonicsRepositoryV2 {
    associatedtype MnemonicItem: Codable

    func hasMnemonic() throws(MnemonicsRepositoryHasAnyFailure) -> Bool

    func add(
        _ mnemonic: MnemonicItem,
        id: CoreMnemonicIdentifier
    ) throws(MnemonicsRepositoryV2SaveFailure)

    func upsert(
        _ mnemonic: MnemonicItem,
        id: CoreMnemonicIdentifier
    ) throws(MnemonicsRepositoryV2UpsertFailure)

    func get(
        id: CoreMnemonicIdentifier
    ) throws(MnemonicsRepositoryV2GetFailure) -> MnemonicItem

    func getAll() throws(MnemonicsRepositoryV2GetFailure) -> [CoreMnemonicIdentifier: MnemonicItem]

    func delete(
        id: CoreMnemonicIdentifier
    ) throws(MnemonicsRepositoryV2DeleteFailure)

    func deleteAll() throws(MnemonicsRepositoryV2DeleteFailure)
}

public protocol RawMnemonicsDataRepositoryV2: MnemonicsRepositoryV2 where MnemonicItem == RawMnemonicsData {}

public struct RawMnemonicsData: Codable {
    var data: Data
}

public enum MnemonicsRepositoryV2Crypto {
    enum Error: Swift.Error {
        case invalidData
        case randomFailed(OSStatus)
        case keyDerivationUnavailable
        case sealedBoxMissingCombined
    }

    private static let version: UInt8 = 1
    private static let keyLength = 32

    public static func encrypt(
        _ mnemonic: CoreMnemonic,
        passcode: String
    ) throws -> RawMnemonicsData {
        let payload = try JSONEncoder().encode(mnemonic)
        let salt = try randomBytes(count: argonSaltLength)
        let key = try deriveArgon2IDKey(passcode: passcode, salt: salt)
        let sealed = try AES.GCM.seal(payload, using: key)
        guard let combined = sealed.combined else {
            throw Error.sealedBoxMissingCombined
        }
        var data = Data()
        data.append(contentsOf: [version])
        data.append(salt)
        data.append(combined)
        return RawMnemonicsData(data: data)
    }

    public static func decrypt(
        _ raw: RawMnemonicsData,
        passcode: String
    ) throws -> CoreMnemonic {
        guard let first = raw.data.first, first == version else {
            throw Error.invalidData
        }
        let saltEndIndex = 1 + argonSaltLength
        guard raw.data.count > saltEndIndex else {
            throw Error.invalidData
        }
        let salt = raw.data.subdata(in: 1 ..< saltEndIndex)
        let combined = raw.data.subdata(in: saltEndIndex ..< raw.data.count)
        let key = try deriveArgon2IDKey(passcode: passcode, salt: salt)
        let sealed = try AES.GCM.SealedBox(combined: combined)
        let decrypted = try AES.GCM.open(sealed, using: key)
        return try JSONDecoder().decode(CoreMnemonic.self, from: decrypted)
    }

    private static func deriveArgon2IDKey(
        passcode: String,
        salt: Data
    ) throws -> SymmetricKey {
        let sodium = Sodium()
        let pwhash = sodium.pwHash
        let derived = pwhash.hash(
            outputLength: keyLength,
            passwd: [UInt8](passcode.utf8),
            salt: [UInt8](salt),
            opsLimit: pwhash.OpsLimitInteractive,
            memLimit: pwhash.MemLimitModerate,
            alg: .Argon2ID13
        )
        guard let derived else {
            throw Error.keyDerivationUnavailable
        }
        return SymmetricKey(data: Data(derived))
    }

    private static var argonSaltLength: Int {
        Sodium().pwHash.SaltBytes
    }

    private static func randomBytes(count: Int) throws -> Data {
        var data = Data(repeating: 0, count: count)
        let result = data.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, count, bytes.baseAddress!)
        }
        guard result == errSecSuccess else {
            throw Error.randomFailed(result)
        }
        return data
    }
}

public struct DefaultMnemonicsRepositoryV2 {
    private let encoder: (CoreMnemonic) throws -> RawMnemonicsData
    private let decoder: (RawMnemonicsData) throws -> CoreMnemonic
    private let rawStorage: any RawMnemonicsDataRepositoryV2

    public init(
        encoder: @escaping (CoreMnemonic) throws -> RawMnemonicsData,
        decoder: @escaping (RawMnemonicsData) throws -> CoreMnemonic,
        rawStorage: any RawMnemonicsDataRepositoryV2
    ) {
        self.encoder = encoder
        self.decoder = decoder
        self.rawStorage = rawStorage
    }
}

extension DefaultMnemonicsRepositoryV2: MnemonicsRepositoryV2 {
    public func hasMnemonic() throws(MnemonicsRepositoryHasAnyFailure) -> Bool {
        try rawStorage.hasMnemonic()
    }

    public func add(
        _ mnemonic: CoreMnemonic,
        id: CoreMnemonicIdentifier
    ) throws(MnemonicsRepositoryV2SaveFailure) {
        let encoded: RawMnemonicsData
        do {
            encoded = try encoder(mnemonic)
        } catch {
            throw .encoding(error)
        }
        try rawStorage.add(encoded, id: id)
    }

    public func upsert(
        _ mnemonic: CoreMnemonic,
        id: CoreMnemonicIdentifier
    ) throws(MnemonicsRepositoryV2UpsertFailure) {
        let encoded: RawMnemonicsData
        do {
            encoded = try encoder(mnemonic)
        } catch {
            throw .encoding(error)
        }
        try rawStorage.upsert(encoded, id: id)
    }

    public func get(
        id: CoreMnemonicIdentifier
    ) throws(MnemonicsRepositoryV2GetFailure) -> CoreMnemonic {
        let raw = try rawStorage.get(id: id)
        let decoded: CoreMnemonic
        do {
            decoded = try decoder(raw)
        } catch {
            throw .decoding(error)
        }
        return decoded
    }

    public func getAll() throws(MnemonicsRepositoryV2GetFailure) -> [CoreMnemonicIdentifier: CoreMnemonic] {
        let rawValues = try rawStorage.getAll()
        var decoded: [CoreMnemonicIdentifier: CoreMnemonic] = [:]
        for (id, rawValue) in rawValues {
            do {
                decoded[id] = try decoder(rawValue)
            } catch {
                throw .decoding(error)
            }
        }
        return decoded
    }

    public func delete(
        id: CoreMnemonicIdentifier
    ) throws(MnemonicsRepositoryV2DeleteFailure) {
        try rawStorage.delete(id: id)
    }

    public func deleteAll() throws(MnemonicsRepositoryV2DeleteFailure) {
        try rawStorage.deleteAll()
    }
}
