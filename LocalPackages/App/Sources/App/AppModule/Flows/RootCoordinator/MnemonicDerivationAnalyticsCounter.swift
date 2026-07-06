import Foundation
import KeeperCore
import KeeperCoreComponents
import KeeperCoreSensitive
import TKCore
import TKLogging
import TonSwift

private extension String {
    static var didCheckMnemonicDerivationWalletsAtStartupKey: String {
        "v1_did_check_mnemonic_derivation_wallets_at_startup"
    }

    static var processedMnemonicDerivationWalletIdentifiersKey: String {
        "v1_processed_mnemonic_derivation_wallet_identifiers"
    }
}

private extension DerivationType {
    var shouldBeCounted: Bool {
        switch self {
        case .bip39, .ton:
            false
        case .unknown, .bip39soft:
            true
        }
    }
}

struct MnemonicDerivationAnalyticsCounterDependencies {
    var logEvent: (_ event: Encodable) -> Void
    var getMnemonic: (_ wallet: Wallet, _ passcode: String) async throws -> CoreMnemonic
    var getWallets: () -> [Wallet]
    var getHistoryState: (_ wallet: Wallet) async -> ActiveWalletTransactionHistory
    var getImportedWallets: (
        _ accounts: [(id: String, address: Address, revision: WalletContractVersion)],
        _ network: Network
    ) async throws -> [ActiveWalletModel]
    var userDefaults: UserDefaults
}

struct MnemonicDerivationAnalyticsCounter {
    private let dependencies: MnemonicDerivationAnalyticsCounterDependencies

    init(dependencies: MnemonicDerivationAnalyticsCounterDependencies) {
        self.dependencies = dependencies
    }
}

extension MnemonicDerivationAnalyticsCounter {
    init(
        walletsUpdateAssembly: WalletsUpdateAssembly,
        analyticsProvider: AnalyticsProvider
    ) {
        let historyService = walletsUpdateAssembly.servicesAssembly.historyService()
        self.init(
            dependencies: MnemonicDerivationAnalyticsCounterDependencies(
                logEvent: {
                    analyticsProvider.log($0)
                },
                getMnemonic: { [mnemonicAccess = walletsUpdateAssembly.secureAssembly.mnemonicAccess] wallet, passcode in
                    try await mnemonicAccess.getMnemonic(wallet: wallet, passcode: passcode)
                },
                getWallets: { [walletsStore = walletsUpdateAssembly.storesAssembly.walletsStore] in
                    walletsStore.wallets
                },
                getHistoryState: { wallet in
                    do {
                        let events = try await historyService.loadEvents(
                            wallet: wallet,
                            beforeLt: nil,
                            limit: 1
                        ).events
                        return events.isEmpty ? .empty : .nonEmpty
                    } catch {
                        Log.w("failed to load wallet history for mnemonic analytics due to error: \(error.localizedDescription)")
                        return .unknown
                    }
                },
                getImportedWallets: { [walletImportController = walletsUpdateAssembly.walletImportController()] accounts, network in
                    try await walletImportController.findActiveWallets(
                        accounts: accounts,
                        network: network,
                        checkHistory: true
                    )
                },
                userDefaults: .standard
            )
        )
    }
}

extension MnemonicDerivationAnalyticsCounter {
    var needsStartupCheck: Bool {
        !dependencies.userDefaults.bool(forKey: .didCheckMnemonicDerivationWalletsAtStartupKey)
    }

    func countWalletsAtStartupIfNeeded(passcode: String) async {
        guard needsStartupCheck else {
            return
        }
        let wallets = dependencies.getWallets()
        guard !wallets.isEmpty else {
            return markStartupChecked()
        }
        send(
            report: await countWallets(
                wallets: wallets,
                passcode: passcode
            )
        )
        markStartupChecked()
    }

    func checkImportedWallets(
        mnemonic: CoreMnemonic,
        revisions: [WalletContractVersion],
        network: Network
    ) async {
        send(
            report: await countImportedWallets(
                mnemonic: mnemonic,
                revisions: revisions,
                network: network
            )
        )
    }

    private func markStartupChecked() {
        dependencies.userDefaults.set(
            true,
            forKey: .didCheckMnemonicDerivationWalletsAtStartupKey
        )
    }
}

extension MnemonicDerivationAnalyticsCounter {
    struct Report {
        struct DerivationCounters {
            var nonEmptyHistory: Int = 0
            var unknownHistory: Int = 0
            var emptyHistory: Int = 0

            var totalCount: Int {
                nonEmptyHistory + unknownHistory + emptyHistory
            }
        }

        var bip39Soft = DerivationCounters()
        var unknownType = DerivationCounters()
        var unclassified: Int = 0
        var identifiers: [String] = []

        var needsToReport: Bool {
            bip39Soft.totalCount + unknownType.totalCount + unclassified > 0
        }

        mutating func markProcessed(_ identifier: String?) {
            guard let identifier else {
                return
            }
            identifiers.append(identifier)
        }

        mutating func add(
            type: DerivationType,
            history: ActiveWalletTransactionHistory,
            count: Int = 1
        ) {
            guard count > 0 else {
                return
            }
            switch type {
            case .bip39soft:
                bip39Soft.add(history: history, count: count)
            case .unknown:
                unknownType.add(history: history, count: count)
            case .ton, .bip39:
                break
            }
        }
    }

    private func send(report: Report) {
        guard report.needsToReport else {
            return markProcessed(report: report)
        }
        let otherMetadata: [String: Int] = [
            "bip39soft_non_empty_history": report.bip39Soft.nonEmptyHistory,
            "bip39soft_unknown_history": report.bip39Soft.unknownHistory,
            "bip39soft_empty_history": report.bip39Soft.emptyHistory,
            "unknown_non_empty_history": report.unknownType.nonEmptyHistory,
            "unknown_unknown_history": report.unknownType.unknownHistory,
            "unknown_empty_history": report.unknownType.emptyHistory,
            "unclassified": report.unclassified,
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
            Log.w("failed to serialize mnemonic analytics metadata payload due to error: \(error)")
            otherMetadataString = nil
        }
        dependencies.logEvent(
            CustomError(
                severity: .warning,
                errorMessage: "unexpected_mnemonic_derivation_detected",
                otherMetadata: otherMetadataString
            )
        )
        markProcessed(report: report)
    }

    private func processedWalletIdentifiers() -> Set<String> {
        Set(
            dependencies.userDefaults.stringArray(
                forKey: .processedMnemonicDerivationWalletIdentifiersKey
            ) ?? []
        )
    }

    private func markProcessed(report: Report) {
        let processedIdentifiers = processedWalletIdentifiers().union(report.identifiers)
        dependencies.userDefaults.set(
            Array(processedIdentifiers).sorted(),
            forKey: .processedMnemonicDerivationWalletIdentifiersKey
        )
    }
}

extension MnemonicDerivationAnalyticsCounter {
    private func countWallets(
        wallets: [Wallet],
        passcode: String
    ) async -> Report {
        let processedIdentifiers = processedWalletIdentifiers()
        var report = Report()

        for wallet in wallets {
            let identifier = try? wallet.address.toRaw()
            if let identifier, processedIdentifiers.contains(identifier) {
                report.markProcessed(identifier)
                continue
            }

            let mnemonic: CoreMnemonic
            do {
                mnemonic = try await dependencies.getMnemonic(wallet, passcode)
            } catch {
                Log.w("failed to load mnemonic for analytics due to error: \(error.localizedDescription)")
                report.unclassified += 1
                continue
            }

            report.markProcessed(identifier)

            guard mnemonic.type.shouldBeCounted else {
                continue
            }
            let history = await dependencies.getHistoryState(wallet)
            report.add(
                type: mnemonic.type,
                history: history
            )
        }

        return report
    }

    private func countImportedWallets(
        mnemonic: CoreMnemonic,
        revisions: [WalletContractVersion],
        network: Network
    ) async -> Report {
        let accounts: [(id: String, address: Address, revision: WalletContractVersion)]
        do {
            accounts = try makeAccounts(
                mnemonic: mnemonic,
                revisions: revisions,
                network: network
            )
        } catch {
            Log.w("failed to prepare imported wallets for analytics due to error: \(error.localizedDescription)")
            var report = Report()
            if mnemonic.type.shouldBeCounted {
                report.add(
                    type: mnemonic.type,
                    history: .unknown,
                    count: max(revisions.count, 1)
                )
            }
            return report
        }

        let processedIdentifiers = processedWalletIdentifiers()
        let accountsToCheck = accounts.filter { !processedIdentifiers.contains($0.address.toRaw()) }

        var report = Report()
        report.identifiers = accounts.map { $0.address.toRaw() }

        guard !accountsToCheck.isEmpty else {
            return report
        }

        let historiesById: [String: ActiveWalletTransactionHistory]
        do {
            let activeWallets = try await dependencies.getImportedWallets(
                accountsToCheck,
                network
            )
            historiesById = Dictionary(
                uniqueKeysWithValues: activeWallets.map {
                    ($0.id, $0.history)
                }
            )
        } catch {
            Log.w("failed to load imported wallet history for analytics due to error: \(error.localizedDescription)")
            if mnemonic.type.shouldBeCounted {
                report.add(
                    type: mnemonic.type,
                    history: .unknown,
                    count: accountsToCheck.count
                )
            }
            return report
        }

        for account in accountsToCheck {
            report.add(
                type: mnemonic.type,
                history: historiesById[account.id] ?? .unknown
            )
        }

        return report
    }

    private func makeAccounts(
        mnemonic: CoreMnemonic,
        revisions: [WalletContractVersion],
        network: Network
    ) throws -> [(id: String, address: Address, revision: WalletContractVersion)] {
        let publicKey = try mnemonic.toKeyPair().publicKey
        return try revisions.map { revision in
            let address = try createAddress(
                publicKey: publicKey,
                revision: revision,
                network: network
            )
            return (id: address.toRaw(), address: address, revision: revision)
        }
    }

    private func createAddress(
        publicKey: TonSwift.PublicKey,
        revision: WalletContractVersion,
        network: Network
    ) throws -> Address {
        let networkRawValue = network.walletNetworkGlobalId

        let contract: WalletContract
        switch revision {
        case .v5R1:
            contract = WalletV5R1(
                publicKey: publicKey.data,
                walletId: WalletId(networkGlobalId: Int32(networkRawValue), workchain: 0)
            )
        case .v5Beta:
            contract = WalletV5Beta(
                publicKey: publicKey.data,
                walletId: WalletIdBeta(networkGlobalId: Int32(networkRawValue), workchain: 0)
            )
        case .v4R2:
            contract = WalletV4R2(publicKey: publicKey.data)
        case .v4R1:
            contract = WalletV4R1(publicKey: publicKey.data)
        case .v3R2:
            contract = try WalletV3(
                workchain: 0,
                publicKey: publicKey.data,
                revision: .r2
            )
        case .v3R1:
            contract = try WalletV3(
                workchain: 0,
                publicKey: publicKey.data,
                revision: .r1
            )
        }
        return try contract.address()
    }
}

private extension MnemonicDerivationAnalyticsCounter.Report.DerivationCounters {
    mutating func add(
        history: ActiveWalletTransactionHistory,
        count: Int
    ) {
        switch history {
        case .empty:
            emptyHistory += count
        case .nonEmpty:
            nonEmptyHistory += count
        case .unknown:
            unknownHistory += count
        }
    }
}
