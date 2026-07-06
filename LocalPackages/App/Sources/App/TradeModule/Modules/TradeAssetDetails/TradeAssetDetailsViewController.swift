import SnapKit
import SwiftUI
import UIKit

final class TradeAssetDetailsViewController: UIViewController {
    private let viewModel: TradeAssetDetailsViewModel
    private let hostingController: UIHostingController<TradeAssetDetailsView>

    init(viewModel: TradeAssetDetailsViewModel) {
        self.viewModel = viewModel
        self.hostingController = UIHostingController(rootView: TradeAssetDetailsView(viewModel: viewModel))
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .Background.page

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        hostingController.view.backgroundColor = .clear
        hostingController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.handleAppear()
    }
}
