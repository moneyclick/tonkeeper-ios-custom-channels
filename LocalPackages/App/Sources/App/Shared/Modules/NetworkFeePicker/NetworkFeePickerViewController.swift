import Combine
import SwiftUI
import TKUIKit
import UIKit

final class NetworkFeePickerViewController: GenericViewViewController<NetworkFeePickerUiView>, TKBottomSheetScrollContentViewController {
    private let viewModel: NetworkFeePickerViewModelImplementation
    private var cancellables = Set<AnyCancellable>()

    var headerConfiguration: TKBottomSheetHeaderConfiguration? {
        viewModel.modalHeaderConfiguration
    }

    var scrollView: UIScrollView {
        customView.scrollView
    }

    var didUpdateHeight: (() -> Void)?
    var didUpdateHeaderConfiguration: ((TKBottomSheetHeaderConfiguration?) -> Void)?

    init(viewModel: NetworkFeePickerViewModelImplementation) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupContent()
        bindViewModel()
        viewModel.viewDidLoad()
    }

    func calculateHeight(withWidth width: CGFloat) -> CGFloat {
        return customView.calculateHeight(width: width)
    }
}

private extension NetworkFeePickerViewController {
    func bindViewModel() {
        viewModel.$viewState
            .dropFirst()
            .sink { [weak self] _ in
                self?.scheduleHeightUpdate()
            }
            .store(in: &cancellables)
    }

    func setupContent() {
        customView.contentHostingView.setContent {
            NetworkFeePickerView(viewModel: viewModel)
        }
        updateHeight()
    }

    func scheduleHeightUpdate() {
        DispatchQueue.main.async { [weak self] in
            self?.updateHeight()
        }
    }

    func updateHeight() {
        customView.contentHostingView.invalidateIntrinsicContentSize()
        customView.setNeedsLayout()
        customView.layoutIfNeeded()
        didUpdateHeight?()
    }
}
