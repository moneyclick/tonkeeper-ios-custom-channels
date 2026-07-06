import TKLocalize
import TKUIKit
import UIKit

final class PickMultichainAddressViewController: GenericViewViewController<PickMultichainAddressUiView>, TKBottomSheetScrollContentViewController {
    private let viewModel: PickMultichainAddressViewModelImplementation

    var headerConfiguration: TKBottomSheetHeaderConfiguration? {
        TKBottomSheetHeaderConfiguration(
            title: .title(
                title: TKLocales.Receive.Multichain.NetworkPicker.title,
                subtitle: TKLocales.Receive.Multichain.NetworkPicker.subtitle
            )
        )
    }

    var scrollView: UIScrollView {
        customView.tableView
    }

    var didUpdateHeight: (() -> Void)?
    var didUpdateHeaderConfiguration: ((TKBottomSheetHeaderConfiguration?) -> Void)?

    init(viewModel: PickMultichainAddressViewModelImplementation) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        customView.tableView.register(
            SwiftUIHostingTableViewCell.self,
            forCellReuseIdentifier: String(describing: SwiftUIHostingTableViewCell.self)
        )
        customView.tableView.dataSource = self
        customView.tableView.reloadData()
    }

    func calculateHeight(withWidth width: CGFloat) -> CGFloat {
        customView.calculateHeight()
    }
}

extension PickMultichainAddressViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = String(describing: SwiftUIHostingTableViewCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        guard let hostingCell = cell as? SwiftUIHostingTableViewCell else {
            return cell
        }

        hostingCell.applyGroupedBackground(
            .init(index: indexPath.row, count: viewModel.items.count)
        )

        let item = viewModel.items[indexPath.row]
        hostingCell.setContent(id: item.id) {
            PickMultichainAddressRowView(
                item: item,
                isSelected: item.address == viewModel.selectedAddress,
                onSelect: { [weak viewModel] in
                    viewModel?.selectAddress(item.address)
                },
                onCopy: { [weak viewModel] in
                    viewModel?.copyAddress(item.address)
                },
                showDivider: indexPath.row < viewModel.items.count - 1
            )
        }

        return hostingCell
    }
}
