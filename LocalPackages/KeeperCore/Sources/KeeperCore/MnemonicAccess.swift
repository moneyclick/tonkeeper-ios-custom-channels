import Foundation
import KeeperCoreComponents
import KeeperCoreSensitive
import TKLogging

public enum MnemonicAccess {
    public struct LegacyRepository {
        public let rn: RNMnemonicsVault
        public let native: MnemonicsVault
    }

    public struct ModernRepository {
        public let raw: MnemonicsRawDataRepository<RawMnemonicsData>
        public let unlocked: (_ seed: String) -> DefaultMnemonicsRepositoryV2
    }

    case v2(
        mnemonicsRepository: ModernRepository,
        passcodeStorage: PasscodeStorage,
        legacyRepository: LegacyRepository
    )
    case disabled(
        mnemonicsRepository: LegacyRepository
    )

    public var legacyRepository: LegacyRepository {
        switch self {
        case let .v2(_, _, legacyRepository), let .disabled(legacyRepository):
            legacyRepository
        }
    }
}

public enum MnemonicAccessError: Swift.Error {
    case passcodeRequired
    case legacyMnemonicInvalid
}

public extension MnemonicAccess {
    func getMnemonic(wallet: Wallet, passcode: String?) async throws -> CoreMnemonic {
        switch self {
        case let .v2(mnemonicsRepositoryV2, _, _):
            let passcode = try requirePasscode(passcode)
            return try mnemonicsRepositoryV2.unlocked(passcode).get(id: wallet.id)
        case let .disabled(mnemonicsRepository):
            let passcode = try requirePasscode(passcode)
            let mnemonic = try await mnemonicsRepository.native.getMnemonic(wallet: wallet, password: passcode)
            return CoreMnemonic(
                mnemonicWords: mnemonic.mnemonicWords,
                type: .guessByWords(
                    mnemonic.mnemonicWords
                )
            )
        }
    }

    func saveMnemonic(_ mnemonic: CoreMnemonic, wallet: Wallet, passcode: String?) async throws {
        let saveMnemonicLegacy: (MnemonicsRepository) async throws -> Void = { repository in
            let passcode = try requirePasscode(passcode)
            let legacyMnemonic = try legacyMnemonic(from: mnemonic)
            try await repository.saveMnemonic(legacyMnemonic, wallet: wallet, password: passcode)
        }
        switch self {
        case let .v2(mnemonicsRepositoryV2, _, legacyRepository):
            let passcode = try requirePasscode(passcode)
            try mnemonicsRepositoryV2.unlocked(passcode).upsert(mnemonic, id: wallet.id)
            do {
                try await saveMnemonicLegacy(legacyRepository.native)
            } catch {
                Log.e("🪵 failed to save mnemonic (legacy) due to: \(error)")
            }
        case let .disabled(mnemonicsRepository):
            try await saveMnemonicLegacy(mnemonicsRepository.native)
        }
    }

    func saveMnemonic(_ mnemonic: CoreMnemonic, wallets: [Wallet], passcode: String?) async throws {
        let saveMnemonicLegacy: (MnemonicsRepository) async throws -> Void = { repository in
            let passcode = try requirePasscode(passcode)
            let legacyMnemonic = try legacyMnemonic(from: mnemonic)
            try await repository.saveMnemonic(legacyMnemonic, wallets: wallets, password: passcode)
        }
        switch self {
        case let .v2(mnemonicsRepositoryV2, _, legacyMnemonicsRepository):
            let passcode = try requirePasscode(passcode)
            for wallet in wallets {
                try mnemonicsRepositoryV2.unlocked(passcode).upsert(mnemonic, id: wallet.id)
            }
            do {
                try await saveMnemonicLegacy(legacyMnemonicsRepository.native)
            } catch {
                Log.e("🪵 failed to save (batch) mnemonic (legacy) due to: \(error)")
            }
        case let .disabled(mnemonicsRepository):
            try await saveMnemonicLegacy(mnemonicsRepository.native)
        }
    }

    func deleteMnemonic(wallet: Wallet, passcode: String?) async throws {
        let deleteMnemonicLegacy: (MnemonicsRepository) async throws -> Void = { repository in
            let passcode = passcode ?? (try? repository.getPassword())
            let resolvedPasscode = try requirePasscode(passcode)
            try await repository.deleteMnemonic(wallet: wallet, password: resolvedPasscode)
        }
        switch self {
        case let .v2(mnemonicsRepositoryV2, passcodeStorage, legacyMnemonicsRepository):
            let resolvedPasscode: String
            if let passcode {
                resolvedPasscode = passcode
            } else {
                do {
                    resolvedPasscode = try passcodeStorage.getPasscode()
                } catch {
                    throw MnemonicAccessError.passcodeRequired
                }
            }
            try mnemonicsRepositoryV2.unlocked(resolvedPasscode).delete(id: wallet.id)
            do {
                try await deleteMnemonicLegacy(legacyMnemonicsRepository.native)
            } catch {
                Log.e("🪵 failed to delete mnemonic (legacy) due to: \(error)")
            }
        case let .disabled(mnemonicsRepository):
            try await deleteMnemonicLegacy(mnemonicsRepository.native)
        }
    }

    func deleteAll(passcode: String?) async throws {
        let deleteMnemonicLegacy: (MnemonicsRepository) async throws -> Void = { repository in
            try await repository.deleteAll()
        }
        switch self {
        case let .v2(mnemonicsRepositoryV2, passcodeStorage, legacyMnemonicsRepository):
            do {
                try mnemonicsRepositoryV2.raw.deleteAll()
            } catch {
                switch error {
                case .notFound:
                    break
                default:
                    throw error
                }
            }
            try passcodeStorage.deletePasscode()
            do {
                try await deleteMnemonicLegacy(legacyMnemonicsRepository.native)
            } catch {
                Log.e("🪵 failed to delete (all) mnemonic (legacy) due to: \(error)")
            }
        case let .disabled(mnemonicsRepository):
            try await deleteMnemonicLegacy(mnemonicsRepository.native)
        }
    }

    func deletePasscode() throws {
        let deletePasscodeLegacy: (MnemonicsRepository) throws -> Void = { repository in
            try repository.deletePassword()
        }
        switch self {
        case let .v2(_, passcodeStorage, mnemonicsRepository):
            try passcodeStorage.deletePasscode()
            do {
                try deletePasscodeLegacy(mnemonicsRepository.native)
            } catch {
                Log.e("🪵 passcode removal (legacy) failed: \(error)")
            }
        case let .disabled(mnemonicsRepository):
            try deletePasscodeLegacy(mnemonicsRepository.native)
        }
    }

    func validatePasscode(_ passcode: String) async -> Bool {
        switch self {
        case let .v2(repository, _, _):
            do {
                _ = try repository.unlocked(passcode).getAll()
                return true
            } catch {
                Log.i("🪵 passcode validation failed: \(error)")
                return false
            }
        case let .disabled(mnemonicsRepository):
            return await mnemonicsRepository.native.checkIfPasswordValid(passcode)
        }
    }

    func changePasscode(old: String, new: String) async throws {
        let legacyChangePasscode: (MnemonicsRepository) async throws -> Void = { mnemonicsRepository in
            try await mnemonicsRepository.changePassword(oldPassword: old, newPassword: new)
        }
        switch self {
        case let .v2(mnemonicsRepository, _, legacyRepository):
            if try mnemonicsRepository.raw.hasMnemonic() {
                let decryptedMnemonics = try mnemonicsRepository.unlocked(old).getAll()
                let newPasscodeRepository = mnemonicsRepository.unlocked(new)

                for (identifier, mnemonic) in decryptedMnemonics {
                    try newPasscodeRepository.upsert(mnemonic, id: identifier)
                }
            }
            do {
                try await legacyChangePasscode(legacyRepository.native)
            } catch {
                Log.e("🪵 legacy passcode change failed: \(error)")
            }
        case .disabled:
            try await legacyChangePasscode(legacyRepository.native)
        }
    }

    func hasMnemonics() -> Bool {
        switch self {
        case let .v2(mnemonicsRepositoryV2, _, _):
            do {
                return try mnemonicsRepositoryV2.raw.hasMnemonic()
            } catch {
                Log.e("🪵 has mnemonics check failed: \(error)")
                return false
            }
        case let .disabled(mnemonicsRepository):
            return mnemonicsRepository.native.hasMnemonics()
        }
    }

    func getPasscode() throws -> String {
        switch self {
        case let .v2(_, passcodeStorage, _):
            try passcodeStorage.getPasscode()
        case let .disabled(mnemonicsRepository):
            try mnemonicsRepository.native.getPassword()
        }
    }

    func setPasscode(_ passcode: String) throws {
        let setPasscodeLegacy: (MnemonicsRepository) throws -> Void = { repository in
            try repository.savePassword(passcode)
        }
        switch self {
        case let .v2(_, passcodeStorage, _):
            try passcodeStorage.setPasscode(passcode)
        case let .disabled(mnemonicsRepository):
            try setPasscodeLegacy(mnemonicsRepository.native)
        }
    }
}

private extension MnemonicAccess {
    func requirePasscode(_ passcode: String?) throws -> String {
        guard let passcode else {
            throw MnemonicAccessError.passcodeRequired
        }
        return passcode
    }

    func legacyMnemonic(from mnemonic: CoreMnemonic) throws -> KeeperCoreComponents.Mnemonic {
        do {
            return try KeeperCoreComponents.Mnemonic(mnemonicWords: mnemonic.mnemonicWords)
        } catch {
            throw MnemonicAccessError.legacyMnemonicInvalid
        }
    }
}
