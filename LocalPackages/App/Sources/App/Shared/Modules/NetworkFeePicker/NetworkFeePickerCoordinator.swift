import TKCoordinator
import TKCore
import TKUIKit

final class NetworkFeePickerCoordinator: RouterCoordinator<NavigationControllerRouter> {
    private weak var bottomSheetViewController: TKBottomSheetViewController?

    func start(
        presentation: NetworkFeePickerPresentation
    ) {
        let module = makeModule(
            presentation: presentation
        )
        let bottomSheetViewController = TKBottomSheetViewController(
            contentViewController: module.view
        )
        self.bottomSheetViewController = bottomSheetViewController

        module.output.didSelectItem = { [presentation] item, category in
            presentation.didSelectItem(item, category)
        }
        module.output.didRequestClose = { [weak bottomSheetViewController] in
            bottomSheetViewController?.dismiss()
        }

        bottomSheetViewController.present(
            fromViewController: router.rootViewController.topPresentedViewController()
        )
    }

    private func makeModule(
        presentation: NetworkFeePickerPresentation
    ) -> MVVMModule<NetworkFeePickerViewController, NetworkFeePickerModuleOutput, NetworkFeePickerModuleInput> {
        let viewModel = NetworkFeePickerViewModelImplementation(
            configuration: presentation.configuration,
            dataSource: presentation.dataSource
        )
        let viewController = NetworkFeePickerViewController(viewModel: viewModel)
        return .init(
            view: viewController,
            output: viewModel,
            input: viewModel
        )
    }
}
