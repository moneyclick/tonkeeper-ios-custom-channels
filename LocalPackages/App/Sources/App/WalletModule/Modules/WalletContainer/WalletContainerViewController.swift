import SnapKit
import TKCoordinator
import TKUIKit
import UIKit

protocol WalletContainerBalanceViewController: UIViewController {
    var didScroll: ((CGFloat) -> Void)? { get set }
}

final class WalletContainerViewController: GenericViewViewController<WalletContainerView>, ScrollViewController {
    private let viewModel: WalletContainerViewModel

    private var walletBalanceViewController: WalletContainerBalanceViewController

    /// for system navigation bar
    private lazy var walletButton = WalletContainerWalletButton()
    private var onTapLeadingButton: (() -> Void)?
    private var onTapHistoryButton: (() -> Void)?
    private var onTapSettingsButton: (() -> Void)?

    var historyButtonTooltipSourceView: UIView? {
        guard isViewLoaded, !UIApplication.useSystemBarsAppearance else {
            return nil
        }
        view.layoutIfNeeded()
        return customView.topBarView.historyButtonTooltipSourceView
    }

    init(
        viewModel: WalletContainerViewModel,
        walletBalanceViewController: WalletContainerBalanceViewController
    ) {
        self.viewModel = viewModel
        self.walletBalanceViewController = walletBalanceViewController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBindings()
        viewModel.viewDidLoad()

        addChild(walletBalanceViewController)
        customView.walletBalanceContainerView.addSubview(walletBalanceViewController.view)
        walletBalanceViewController.didMove(toParent: self)

        walletBalanceViewController.view.snp.makeConstraints { make in
            make.edges.equalTo(customView.walletBalanceContainerView)
        }

        walletBalanceViewController.didScroll = { [weak self] yOffset in
            self?.customView.topBarView.isSeparatorHidden = yOffset <= 0
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !UIApplication.useSystemBarsAppearance {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        customView.layoutIfNeeded()

        if !UIApplication.useSystemBarsAppearance {
            walletBalanceViewController.additionalSafeAreaInsets.top = customView.topBarView.frame.height - customView.safeAreaInsets.top
        }
    }

    func scrollToTop() {
        (walletBalanceViewController as? ScrollViewController)?.scrollToTop()
    }
}

private extension WalletContainerViewController {
    func setupBindings() {
        viewModel.didUpdateModel = { [customView, weak self] model in
            self?.setupNavigationBarIfNeeded(with: model)
            customView.configure(model: model)
        }

        customView.topBarView.walletButton.didTap = { [weak viewModel] in
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            viewModel?.didTapWalletButton()
        }
    }
}

// MARK: - System Navigation Bar

private extension WalletContainerViewController {
    func setupNavigationBarIfNeeded(with model: WalletContainerView.Model) {
        guard UIApplication.useSystemBarsAppearance else {
            return
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: walletButton)
        walletButton.configure(model: model.topBarViewModel.walletButtonConfiguration)
        walletButton.didTap = { [weak self] in
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            self?.viewModel.didTapWalletButton()
        }

        let barButtonItems = [
            UIBarButtonItem(
                image: model.topBarViewModel.settingButtonConfiguration.configuration.content.icon,
                style: .plain,
                target: self,
                action: #selector(didTapSettingsButton)
            ),
            model.topBarViewModel.historyButtonConfiguration.map { historyButtonConfiguration in
                UIBarButtonItem(
                    image: historyButtonConfiguration.content.icon,
                    style: .plain,
                    target: self,
                    action: #selector(didTapHistoryButton)
                )
            },
            UIBarButtonItem(
                image: model.topBarViewModel.leadingButtonConfiguration.content.icon,
                style: .plain,
                target: self,
                action: #selector(didTapLeadingButton)
            ),
        ].compactMap { $0 }

        let window = windowScene?.windows.first
        let width = window?.screen.bounds.width ?? 0
        walletButton.snp.makeConstraints { make in
            let multiplicator: CGFloat
            if barButtonItems.count <= 2 {
                multiplicator = 0.5
            } else {
                multiplicator = 0.33
            }
            make.width.lessThanOrEqualTo(max(width * multiplicator, 160))
        }
        navigationItem.rightBarButtonItems = barButtonItems

        onTapSettingsButton = model.topBarViewModel.settingButtonConfiguration.configuration.action
        onTapLeadingButton = model.topBarViewModel.leadingButtonConfiguration.action
        onTapHistoryButton = model.topBarViewModel.historyButtonConfiguration?.action
    }

    @objc
    func didTapSettingsButton() {
        onTapSettingsButton?()
    }

    @objc
    func didTapLeadingButton() {
        onTapLeadingButton?()
    }

    @objc
    func didTapHistoryButton() {
        onTapHistoryButton?()
    }
}
