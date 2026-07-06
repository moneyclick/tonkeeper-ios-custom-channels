import KeeperCore
import TKCoordinator
import TKCore
import TKLocalize
import UIKit

final class MultichainSwapTransactionConfirmationCoordinator: RouterCoordinator<NavigationControllerRouter> {
    var didClose: (() -> Void)?
    var didRequestOpenBuySell: ((_ isInternalPurchasing: Bool) -> Void)?
    var didTapEdit: ((Bool?) -> Void)?
    var didTapBack: (() -> Void)?

    private let confirmationInput: MultichainSwapConfirmationInput
    private let rateText: String
    private var confirmationViewModel: MultichainSwapTransactionConfirmationViewModel?
    private var networkFeePickerCoordinator: NetworkFeePickerCoordinator?
    private var priceImpactCoordinator: PriceImpactCoordinator?

    init(
        wallet _: Wallet,
        nativeSwapContext _: NativeSwapContext,
        keeperCoreMainAssembly _: KeeperCore.MainAssembly,
        coreAssembly _: TKCore.CoreAssembly,
        router: NavigationControllerRouter,
        confirmationInput: MultichainSwapConfirmationInput,
        rateText: String
    ) {
        self.confirmationInput = confirmationInput
        self.rateText = rateText
        super.init(router: router)
    }

    override func start(deeplink: (any CoordinatorDeeplink)? = nil) {
        openConfirmation()
    }

    func handleTonkeeperPublishDeeplink(sign _: Data) -> Bool {
        false
    }

    func cancelPendingSignerFlow() {}
}

private extension MultichainSwapTransactionConfirmationCoordinator {
    func openConfirmation() {
        let viewModel = MultichainSwapTransactionConfirmationViewModel(
            confirmationInput: confirmationInput,
            rateText: rateText,
            onBack: { [weak self] in
                guard let self else { return }
                didTapBack?()
                router.rootViewController.popViewController(animated: true)
            },
            onClose: { [weak self] in
                self?.didClose?()
            },
            onSwipeConfirm: { [weak self] in
                self?.openPriceImpact()
            },
            onTapNetworkFeeMethod: { [weak self] in
                self?.openNetworkFeePicker()
            }
        )
        confirmationViewModel = viewModel
        let viewController = MultichainSwapTransactionConfirmationViewController(viewModel: viewModel)

        router.push(viewController: viewController)
    }

    func openNetworkFeePicker() {
        guard let confirmationViewModel else {
            return
        }
        let methods = ["BTC", "TON", "USDT"]
        let items = methods.map { method in
            NetworkFeePickerItem(
                id: method,
                leading: .assetAvatar(imageSource: confirmationInput.sendAsset.swapAvatarSource),
                text: .singleLine(title: method)
            )
        }
        let presentation = NetworkFeePickerPresentation(
            configuration: .init(
                title: TKLocales.FeeMethodPicker.title,
                subtitle: TKLocales.FeeMethodPicker.subtitle
            ),
            dataSource: StaticNetworkFeePickerDataSource(items: items),
            didSelectItem: { item, _ in
                confirmationViewModel.selectNetworkFeeMethod(item.id)
            }
        )

        let coordinator = NetworkFeePickerCoordinator(router: router)
        networkFeePickerCoordinator = coordinator
        coordinator.start(presentation: presentation)
    }

    func openPriceImpact() {
        let presentation = PriceImpactPresentation(
            title: "Price impact is too high",
            subtitle: "Swap may be conducted at a rate that differs significantly from market prices.",
            description: "Please wait a little longer before conducting this exchange, or try changing the amount to be swapped.",
            confirmButtonTitle: "Swap at the Changed Price",
            backButtonTitle: "Back to Swap",
            didTapClose: {},
            didTapConfirm: {},
            didTapBack: {}
        )

        let coordinator = PriceImpactCoordinator(router: router)
        priceImpactCoordinator = coordinator
        coordinator.start(presentation: presentation)
    }
}
