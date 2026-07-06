import KeeperCore
import TKCoordinator
import TKCore
import TKUIKit
import UIKit

public final class MultichainSwapCoordinator: RouterCoordinator<NavigationControllerRouter> {
    var didRequestOpenBuySell: ((_ isInternalPurchasing: Bool) -> Void)?

    private let wallet: Wallet
    private let nativeSwapContext: NativeSwapContext
    private let coreAssembly: TKCore.CoreAssembly
    private let keeperCoreMainAssembly: KeeperCore.MainAssembly

    private weak var confirmationCoordinator: MultichainSwapTransactionConfirmationCoordinator?
    private weak var multichainSwapViewModel: MultichainSwapViewModel?

    public init(
        wallet: Wallet,
        nativeSwapContext: NativeSwapContext,
        router: NavigationControllerRouter,
        coreAssembly: TKCore.CoreAssembly,
        keeperCoreMainAssembly: KeeperCore.MainAssembly
    ) {
        self.wallet = wallet
        self.nativeSwapContext = nativeSwapContext
        self.coreAssembly = coreAssembly
        self.keeperCoreMainAssembly = keeperCoreMainAssembly
        super.init(router: router)
    }

    override public func start() {
        openSwap()
    }

    public func handleTonkeeperPublishDeeplink(sign: Data) -> Bool {
        confirmationCoordinator?.handleTonkeeperPublishDeeplink(sign: sign) ?? false
    }

    override public func didMoveTo(toParent parent: Coordinator?) {
        if parent == nil {
            confirmationCoordinator?.cancelPendingSignerFlow()
        }
    }
}

private extension MultichainSwapCoordinator {
    enum MultichainSwapTokenPickSide {
        case send
        case receive
    }

    func openSwap() {
        router.rootViewController.setNavigationBarHidden(true, animated: false)

        let viewModel = MultichainSwapViewModel(
            amountFormatter: keeperCoreMainAssembly.formattersAssembly.amountFormatter,
            sendAsset: MultichainSwapDefaultAssets.sendAsset(for: wallet),
            receiveAsset: MultichainSwapDefaultAssets.receiveAsset(for: wallet),
            onClose: { [weak self] in
                guard let self else { return }
                didFinish?(self)
            },
            onContinue: { [weak self] in
                self?.openConfirmation()
            }
        )
        multichainSwapViewModel = viewModel
        viewModel.onRequestPickSendToken = { [weak self] in
            self?.presentSendTokenV2Picker(side: .send)
        }
        viewModel.onRequestPickReceiveToken = { [weak self] in
            self?.presentSendTokenV2Picker(side: .receive)
        }
        let viewController = MultichainSwapViewController(viewModel: viewModel)
        router.push(viewController: viewController)
    }

    func presentSendTokenV2Picker(side: MultichainSwapTokenPickSide) {
        guard let swapViewModel = multichainSwapViewModel else {
            return
        }

        let selectedAsset: MultichainAsset?
        let searchBehavior: SendTokenV2PickerSearchBehavior
        switch side {
        case .send:
            selectedAsset = swapViewModel.sendAsset
            searchBehavior = .account
        case .receive:
            selectedAsset = swapViewModel.receiveAsset
            searchBehavior = .catalog
        }

        let model = SendTokenV2PickerModel(
            wallet: wallet,
            displayMode: .includingSelection(selectedAsset),
            searchBehavior: searchBehavior,
            multichainService: keeperCoreMainAssembly.servicesAssembly.multichainService(),
            currencyStore: keeperCoreMainAssembly.storesAssembly.currencyStore
        )

        let module = TokenPickerV2Assembly.module(
            wallet: wallet,
            model: model,
            keeperCoreMainAssembly: keeperCoreMainAssembly
        )

        let bottomSheetViewController = TKBottomSheetViewController(
            contentViewController: module.view
        )

        module.output.didSelectAsset = { [weak self] asset in
            guard let self else { return }
            switch side {
            case .send:
                self.multichainSwapViewModel?.applySendAsset(asset)
            case .receive:
                self.multichainSwapViewModel?.applyReceiveAsset(asset)
            }
        }

        module.output.didFinish = { [weak bottomSheetViewController] in
            bottomSheetViewController?.dismiss()
        }

        bottomSheetViewController.present(
            fromViewController: router.rootViewController.topPresentedViewController()
        )
    }

    func openConfirmation() {
        guard let swapViewModel = multichainSwapViewModel else {
            return
        }

        let coordinator = MultichainSwapTransactionConfirmationCoordinator(
            wallet: wallet,
            nativeSwapContext: nativeSwapContext,
            keeperCoreMainAssembly: keeperCoreMainAssembly,
            coreAssembly: coreAssembly,
            router: router,
            confirmationInput: swapViewModel.makeConfirmationInput(),
            rateText: swapViewModel.rateText
        )

        coordinator.didFinish = { [weak self] in
            self?.removeChild($0)
        }

        coordinator.didClose = { [weak self, weak coordinator] in
            self?.didFinish?(self)
            self?.removeChild(coordinator)
        }

        coordinator.didTapEdit = { [weak self, weak coordinator] _ in
            self?.removeChild(coordinator)
        }

        coordinator.didTapBack = { [weak self, weak coordinator] in
            self?.removeChild(coordinator)
        }

        coordinator.didRequestOpenBuySell = { [weak self, weak coordinator] isInternalPurchasing in
            self?.didRequestOpenBuySell?(isInternalPurchasing)
            self?.didFinish?(self)
            self?.removeChild(coordinator)
        }

        confirmationCoordinator = coordinator

        addChild(coordinator)
        coordinator.start(deeplink: nil)
    }
}
