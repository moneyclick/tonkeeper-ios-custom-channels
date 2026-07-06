import TKCoordinator
import TKCore
import TKUIKit

final class PriceImpactCoordinator: RouterCoordinator<NavigationControllerRouter> {
    private weak var bottomSheetViewController: TKBottomSheetViewController?

    func start(presentation: PriceImpactPresentation) {
        let viewController = PriceImpactViewController(
            presentation: PriceImpactPresentation(
                title: presentation.title,
                subtitle: presentation.subtitle,
                description: presentation.description,
                confirmButtonTitle: presentation.confirmButtonTitle,
                backButtonTitle: presentation.backButtonTitle,
                didTapClose: { [weak self] in
                    self?.dismiss()
                    presentation.didTapClose()
                },
                didTapConfirm: { [weak self] in
                    self?.dismiss()
                    presentation.didTapConfirm()
                },
                didTapBack: { [weak self] in
                    self?.dismiss()
                    presentation.didTapBack()
                }
            )
        )
        let bottomSheetViewController = TKBottomSheetViewController(
            contentViewController: viewController
        )
        self.bottomSheetViewController = bottomSheetViewController
        bottomSheetViewController.present(
            fromViewController: router.rootViewController.topPresentedViewController()
        )
    }
}

private extension PriceImpactCoordinator {
    func dismiss() {
        bottomSheetViewController?.dismiss()
    }
}
