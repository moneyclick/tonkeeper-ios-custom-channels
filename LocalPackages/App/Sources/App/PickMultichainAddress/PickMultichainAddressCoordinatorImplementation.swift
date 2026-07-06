import KeeperCore
import TKCoordinator
import TKCore
import TKUIKit
import UIKit

@MainActor
final class PickMultichainAddressCoordinatorImplementation<V: UIViewController>: RouterCoordinator<ContainerViewControllerRouter<V>> {
    private let addresses: [MultichainWalletAddress]
    private let selectedAddress: MultichainWalletAddress?

    private weak var presentedBottomSheetViewController: TKBottomSheetViewController?
    private var streamContinuation: AsyncStream<PickMultichainAddressCoordinatorEvent>.Continuation?
    private var didFinishStream = false

    init(
        router: ContainerViewControllerRouter<V>,
        addresses: [MultichainWalletAddress],
        selectedAddress: MultichainWalletAddress?
    ) {
        self.addresses = addresses
        self.selectedAddress = selectedAddress
        super.init(router: router)
    }

    override func start() {
        let module = module()

        let bottomSheetViewController = TKBottomSheetViewController(
            contentViewController: module.view
        )
        bottomSheetViewController.didClose = { [weak self] _ in
            self?.finishStream()
        }
        presentedBottomSheetViewController = bottomSheetViewController
        bottomSheetViewController.present(
            fromViewController: router.rootViewController.topPresentedViewController()
        )
    }
}

extension PickMultichainAddressCoordinatorImplementation: PickMultichainAddressCoordinator {
    func startHandlingEvents() -> AsyncStream<PickMultichainAddressCoordinatorEvent> {
        AsyncStream { [weak self] continuation in
            guard let self else {
                return continuation.finish()
            }
            streamContinuation = continuation
            didFinishStream = false
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.streamContinuation = nil
                }
            }
            start()
        }
    }
}

private extension PickMultichainAddressCoordinatorImplementation {
    func module() -> MVVMModule<
        PickMultichainAddressViewController,
        PickMultichainAddressModuleOutput,
        PickMultichainAddressModuleInput
    > {
        let viewModel = PickMultichainAddressViewModelImplementation(
            addresses: addresses,
            selectedAddress: selectedAddress
        )
        viewModel.didSelectAddress = { [weak self] address in
            self?.streamContinuation?.yield(.select(address))
        }
        viewModel.didCopyAddress = { [weak self] address in
            self?.streamContinuation?.yield(.copy(address))
        }
        viewModel.didRequestClose = { [weak self] in
            self?.dismissBottomSheet {
                self?.finishStream()
            }
        }
        let viewController = PickMultichainAddressViewController(viewModel: viewModel)
        return MVVMModule(
            view: viewController,
            output: viewModel,
            input: viewModel
        )
    }

    func dismissBottomSheet(completion: (() -> Void)? = nil) {
        presentedBottomSheetViewController?.dismiss(completion: completion)
    }

    func finishStream() {
        guard !didFinishStream else { return }
        didFinishStream = true
        streamContinuation?.yield(.close)
        streamContinuation?.finish()
        streamContinuation = nil
    }
}
