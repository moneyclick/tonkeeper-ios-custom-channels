import KeeperCore
import TKCoordinator
import TKCore
import TKLogging
import TKUIKit
import UIKit

protocol ReceiveLegacyTokenConvertible {
    var receiveLegacyToken: ReceiveLegacyToken? { get }
}

extension Token: ReceiveLegacyTokenConvertible {
    var receiveLegacyToken: ReceiveLegacyToken? {
        switch self {
        case let .ton(ton):
            .ton(ton)
        case let .tron(tron):
            .tron(tron)
        }
    }
}

enum ReceiveLegacyToken: Equatable, Hashable {
    case ton(TonToken)
    case tron(TronToken)
}

extension ReceiveLegacyToken {
    var token: Token {
        switch self {
        case let .ton(ton):
            .ton(ton)
        case let .tron(tron):
            .tron(tron)
        }
    }
}

@MainActor
struct ReceiveModule {
    private let dependencies: Dependencies
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func createReceiveCoordinator<V: UIViewController>(
        router: ContainerViewControllerRouter<V>,
        wallet: Wallet,
        address: MultichainWalletAddress
    ) -> ReceiveCoordinator {
        MultichainReceiveCoordinator(
            router: router,
            addresses: .single(address),
            keeperCoreMainAssembly: dependencies.keeperCoreMainAssembly,
            didCopyAddress: { address in
                Task { @MainActor in
                    UIPasteboard.general.string = address
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    ToastPresenter.showToast(configuration: wallet.copyToastConfiguration())
                }
            }
        )
    }

    func createReceiveCoordinator<V: UIViewController>(
        router: ContainerViewControllerRouter<V>,
        wallet: Wallet,
        addresses: [MultichainWalletAddress]
    ) -> ReceiveCoordinator {
        MultichainReceiveCoordinator(
            router: router,
            addresses: .multi(addresses),
            keeperCoreMainAssembly: dependencies.keeperCoreMainAssembly,
            didCopyAddress: { address in
                Task { @MainActor in
                    UIPasteboard.general.string = address
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    ToastPresenter.showToast(configuration: wallet.copyToastConfiguration())
                }
            }
        )
    }

    func createReceiveCoordinator<V: UIViewController>(
        router: ContainerViewControllerRouter<V>,
        tokens: [ReceiveLegacyTokenConvertible],
        wallet: Wallet,
        passcodeProvider: (() async -> String?)? = nil,
        didDisplayToken: ((Token) -> Void)? = nil
    ) -> ReceiveCoordinator {
        LegacyReceiveCoordinator(
            router: router,
            tokens: tokens.compactMap {
                guard let token = $0.receiveLegacyToken else {
                    Log.w("failed to map token \($0) to receive legacy token")
                    return nil
                }
                return token
            },
            wallet: wallet,
            keeperCoreMainAssembly: dependencies.keeperCoreMainAssembly,
            passcodeProvider: passcodeProvider,
            didDisplayToken: didDisplayToken
        )
    }
}

extension ReceiveModule {
    struct Dependencies {
        let coreAssembly: TKCore.CoreAssembly
        let keeperCoreMainAssembly: KeeperCore.MainAssembly

        init(
            coreAssembly: TKCore.CoreAssembly,
            keeperCoreMainAssembly: KeeperCore.MainAssembly
        ) {
            self.coreAssembly = coreAssembly
            self.keeperCoreMainAssembly = keeperCoreMainAssembly
        }
    }
}
