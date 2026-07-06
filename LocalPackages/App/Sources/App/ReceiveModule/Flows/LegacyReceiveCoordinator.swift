import KeeperCore
import TKCoordinator
import TKCore
import TKUIKit
import UIKit

@MainActor
final class LegacyReceiveCoordinator<V: UIViewController>: RouterCoordinator<ContainerViewControllerRouter<V>>, ReceiveCoordinator {
    var didClose: (() -> Void)?

    private let tokens: [ReceiveLegacyToken]
    private let wallet: Wallet
    private let keeperCoreMainAssembly: KeeperCore.MainAssembly
    private let passcodeProvider: (() async -> String?)?
    private let didDisplayToken: ((Token) -> Void)?

    init(
        router: ContainerViewControllerRouter<V>,
        tokens: [ReceiveLegacyToken],
        wallet: Wallet,
        keeperCoreMainAssembly: KeeperCore.MainAssembly,
        passcodeProvider: (() async -> String?)?,
        didDisplayToken: ((Token) -> Void)?
    ) {
        self.tokens = tokens
        self.wallet = wallet
        self.keeperCoreMainAssembly = keeperCoreMainAssembly
        self.passcodeProvider = passcodeProvider
        self.didDisplayToken = didDisplayToken
        super.init(router: router)
    }

    override func start() {
        let module = module(tokens: tokens, wallet: wallet)
        let navigationController = TKNavigationController(
            rootViewController: module.view
        )
        navigationController.setNavigationBarHidden(true, animated: false)
        router.presentOverTopPresented(navigationController)
    }
}

extension LegacyReceiveCoordinator {
    private func module(
        tokens: [ReceiveLegacyToken],
        wallet: Wallet
    ) -> MVVMModule<UIViewController, ReceiveModuleOutput, ReceiveModuleInput> {
        weak var weakModel: ReceiveLegacyViewModelImplementation?
        let keeperCoreMainAssembly = keeperCoreMainAssembly
        let viewModel = ReceiveLegacyViewModelImplementation(
            tokens: tokens,
            wallet: wallet,
            walletsStore: keeperCoreMainAssembly.storesAssembly.walletsStore,
            didSelectInactiveTRC20: { [weak self] wallet in
                self?.openReceiveTRC20Popup(
                    wallet: wallet,
                    enableCompletion: {
                        weakModel?.selectToken(token: .tron(.usdt))
                    }
                )
            },
            tokenModuleViewControllerProvider: { receiveItem in
                ReceiveTabAssembly.module(
                    token: receiveItem,
                    wallet: wallet,
                    qrCodeGenerator: QRCodeGeneratorImplementation(),
                    keeperCoreAssembly: keeperCoreMainAssembly
                ).view
            }
        )
        weakModel = viewModel
        let didDisplayToken = self.didDisplayToken
        viewModel.didDisplayToken = { token in
            didDisplayToken?(token.token)
        }
        viewModel.didRequestClose = { [weak self, router] in
            router.dismiss(completion: self?.didClose)
        }
        let viewController = ReceiveLegacyViewController(viewModel: viewModel)
        return MVVMModule(
            view: viewController,
            output: viewModel,
            input: viewModel
        )
    }

    private func openReceiveTRC20Popup(
        wallet: Wallet,
        enableCompletion: @escaping () -> Void
    ) {
        guard let passcodeProvider else {
            return
        }

        let module = ReceiveTRC20PopupAssembly.module(
            wallet: wallet,
            keeperCoreAssembly: keeperCoreMainAssembly,
            passcodeProvider: passcodeProvider
        )
        let bottomSheetViewController = TKBottomSheetViewController(contentViewController: module.view)
        bottomSheetViewController.present(fromViewController: router.rootViewController.topPresentedViewController())

        module.output.didFinish = { [weak bottomSheetViewController] in
            bottomSheetViewController?.dismiss()
        }

        module.output.didEnable = {
            enableCompletion()
        }
    }
}
