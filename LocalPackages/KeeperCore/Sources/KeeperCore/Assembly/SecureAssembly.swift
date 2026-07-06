import Foundation
import KeeperCoreComponents
import KeeperCoreSensitive

public final class SecureAssembly {
    private let coreAssembly: CoreAssembly
    private let configurationAssembly: ConfigurationAssembly

    init(
        coreAssembly: CoreAssembly,
        configurationAssembly: ConfigurationAssembly
    ) {
        self.coreAssembly = coreAssembly
        self.configurationAssembly = configurationAssembly
    }

    public private(set) lazy var mnemonicAccess = createMnemonicAccess()

    private func createMnemonicAccess() -> MnemonicAccess {
        let legacy = MnemonicAccess.LegacyRepository(
            rn: coreAssembly.rnMnemonicsVault(),
            native: coreAssembly.mnemonicsVault()
        )
        if configurationAssembly.configuration.featureEnabled(.mnemonicsStorageV2) {
            let raw = MnemonicsRawDataRepository<RawMnemonicsData>(
                seedProvider: coreAssembly.seedProvider
            )
            let modern = MnemonicAccess.ModernRepository(
                raw: raw,
                unlocked: { passcode in
                    DefaultMnemonicsRepositoryV2(
                        encoder: { mnemonic in
                            try MnemonicsRepositoryV2Crypto.encrypt(mnemonic, passcode: passcode)
                        },
                        decoder: { rawValue in
                            try MnemonicsRepositoryV2Crypto.decrypt(rawValue, passcode: passcode)
                        },
                        rawStorage: raw
                    )
                }
            )
            return .v2(
                mnemonicsRepository: modern,
                passcodeStorage: PasscodeStorage(seedProvider: coreAssembly.seedProvider),
                legacyRepository: legacy
            )
        } else {
            return .disabled(
                mnemonicsRepository: legacy
            )
        }
    }
}
