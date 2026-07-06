import Foundation
import KeeperCore
import TKCore
import TKLogging
import TronSwift

typealias BrokenTronAddress = TronSwift.Address

private extension String {
    static var didCheckBrokenTronWalletsAtStartupKey: String {
        "v1_did_check_broken_tron_wallets_at_startup"
    }

    static var processedTronWalletAddressesKey: String {
        "v1_processed_tron_wallet_addresses"
    }
}

struct BrokenTronWalletAnalyticsCounterDependencies {
    var logEvent: (_ event: Encodable) -> Void
    var getMnemonicWords: (_ wallet: Wallet, _ password: String) async throws -> [String]
    var getWallets: () -> [Wallet]
    var hasTransactions: (_ address: BrokenTronAddress) async throws -> Bool
    var userDefaults: UserDefaults
}

struct BrokenTronWalletAnalyticsCounter {
    private let dependencies: BrokenTronWalletAnalyticsCounterDependencies

    init(dependencies: BrokenTronWalletAnalyticsCounterDependencies) {
        self.dependencies = dependencies
    }
}

extension BrokenTronWalletAnalyticsCounter {
    init(
        walletsUpdateAssembly: WalletsUpdateAssembly,
        analyticsProvider: AnalyticsProvider
    ) {
        self.init(
            dependencies: BrokenTronWalletAnalyticsCounterDependencies(
                logEvent: {
                    analyticsProvider.log($0)
                },
                getMnemonicWords: { [mnemonicAccess = walletsUpdateAssembly.secureAssembly.mnemonicAccess] wallet, password in
                    try await mnemonicAccess.getMnemonic(wallet: wallet, passcode: password).mnemonicWords
                },
                getWallets: { [walletsStore = walletsUpdateAssembly.storesAssembly.walletsStore] in
                    walletsStore.wallets
                },
                hasTransactions: { [tronUsdtApi = walletsUpdateAssembly.servicesAssembly.tronUsdtApi()] in
                    try await tronUsdtApi.hasTransactions(address: $0)
                },
                userDefaults: .standard
            )
        )
    }
}

extension BrokenTronWalletAnalyticsCounter {
    var needsStartupCheck: Bool {
        !dependencies.userDefaults.bool(forKey: .didCheckBrokenTronWalletsAtStartupKey)
    }

    func countWalletsAtStartupIfNeeded(passcode: String) async {
        guard needsStartupCheck else {
            return
        }
        let wallets = dependencies.getWallets()
            .filter { $0.network == .mainnet }
        guard !wallets.isEmpty else {
            return markStartupChecked()
        }
        await send(
            report: countAffectedWallets(
                wallets: wallets,
                passcode: passcode
            )
        )
        markStartupChecked()
    }

    func checkImportedMnemonics(words: [String]) async {
        await send(
            report: countAffectedMnemonics(
                mnemonics: [words]
            )
        )
    }

    private func markStartupChecked() {
        dependencies.userDefaults.set(
            true,
            forKey: .didCheckBrokenTronWalletsAtStartupKey
        )
    }
}

extension BrokenTronWalletAnalyticsCounter {
    struct BrokenWalletsReport {
        var invalidWithHistory: Int
        var invalidWithUnknownHistory: Int
        var invalidEmpty: Int
        var unknown: Int
        var addresses: [TronSwift.Address]

        var needsToReport: Bool {
            let totalCount = invalidWithHistory + invalidWithUnknownHistory + invalidEmpty + unknown
            return totalCount > 0
        }
    }

    private func send(
        report: BrokenWalletsReport
    ) async {
        guard report.needsToReport else {
            return markProcessed(report: report)
        }
        let otherMetadata: [String: Int] = [
            "affected_empty_history": report.invalidEmpty,
            "affected_unknown_history": report.invalidWithUnknownHistory,
            "affected_non_empty_history": report.invalidWithHistory,
            "unknown": report.unknown,
        ].filter {
            $0.value > 0
        }
        let otherMetadataString: String?
        do {
            otherMetadataString = try String(
                data: JSONSerialization.data(
                    withJSONObject: otherMetadata,
                    options: [.sortedKeys]
                ),
                encoding: .utf8
            )
        } catch {
            Log.w("failed to serialize broken wallets analytics metadata payload due to error: \(error)")
            otherMetadataString = nil
        }
        dependencies.logEvent(
            CustomError(
                severity: .warning,
                errorMessage: "tron_broken_address_detected",
                otherMetadata: otherMetadataString
            )
        )
        markProcessed(report: report)
    }

    private func processedTronWalletAddresses() -> Set<String> {
        Set(
            dependencies.userDefaults.stringArray(forKey: .processedTronWalletAddressesKey) ?? []
        )
    }

    private func markProcessed(report: BrokenWalletsReport) {
        let processedAddresses = processedTronWalletAddresses().union(
            report.addresses.map(\.base58)
        )
        dependencies.userDefaults.set(
            Array(processedAddresses).sorted(),
            forKey: .processedTronWalletAddressesKey
        )
    }
}

extension BrokenTronWalletAnalyticsCounter {
    private func countAffectedWallets(
        wallets: [Wallet],
        passcode: String
    ) async -> BrokenWalletsReport {
        var mnemonics: [[String]] = []
        var unknownCount = 0
        for wallet in wallets {
            let mnemonicWords: [String]
            do {
                mnemonicWords = try await dependencies.getMnemonicWords(wallet, passcode)
            } catch {
                Log.w("failed to check if there are any invalid tron addresses due to error: \(error.localizedDescription)")
                unknownCount += 1
                continue
            }
            mnemonics.append(mnemonicWords)
        }
        return await {
            var counted = await countAffectedMnemonics(mnemonics: mnemonics)
            counted.unknown += unknownCount
            return counted
        }()
    }

    private func countAffectedMnemonics(
        mnemonics: [[String]]
    ) async -> BrokenWalletsReport {
        let mnemonics = mnemonics.removingDuplicatedElements()
        var invalidWithHistoryCount = 0
        var invalidWithUnknownHistoryCount = 0
        var invalidEmptyCount = 0
        var unknownCount = 0
        var checkedAddresses: [TronSwift.Address] = []

        let processedAddresses = processedTronWalletAddresses()

        for mnemonicWords in mnemonics {
            let legacyAddress: TronSwift.Address
            let fixedAddress: TronSwift.Address
            do {
                (legacyAddress, fixedAddress) = try getTronAddresses(mnemonicWords: mnemonicWords)
            } catch {
                Log.w("failed to check if there are any invalid tron addresses due to error: \(error.localizedDescription)")
                unknownCount += 1
                continue
            }
            checkedAddresses.append(legacyAddress)
            guard legacyAddress != fixedAddress, !processedAddresses.contains(legacyAddress.base58) else {
                continue
            }
            let hasTransactions: Bool
            do {
                hasTransactions = try await dependencies.hasTransactions(legacyAddress)
            } catch {
                Log.w("failed to check if there are any invalid tron addresses due to error: \(error.localizedDescription)")
                invalidWithUnknownHistoryCount += 1
                continue
            }
            guard hasTransactions else {
                invalidEmptyCount += 1
                continue
            }
            invalidWithHistoryCount += 1
        }

        return BrokenWalletsReport(
            invalidWithHistory: invalidWithHistoryCount,
            invalidWithUnknownHistory: invalidWithUnknownHistoryCount,
            invalidEmpty: invalidEmptyCount,
            unknown: unknownCount,
            addresses: checkedAddresses
        )
    }

    private func getTronAddresses(mnemonicWords: [String]) throws -> (
        legacyAddress: TronSwift.Address,
        fixedAddress: TronSwift.Address
    ) {
        let legacyKeyPair = try TonTron.derivedKeyPair(
            tonMnemonic: mnemonicWords,
            index: 0,
            useBip39DerivationForBip39Mnemonics: false
        )
        let fixedKeyPair = try TonTron.derivedKeyPair(
            tonMnemonic: mnemonicWords,
            index: 0,
            useBip39DerivationForBip39Mnemonics: true
        )
        return try (
            legacyAddress: Address(publicKey: legacyKeyPair.publicKey),
            fixedAddress: Address(publicKey: fixedKeyPair.publicKey)
        )
    }
}
