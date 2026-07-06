import SnapKit
import TKUIKit
import UIKit

final class PickMultichainAddressUiView: UIView {
    let tableView = UITableView(frame: .zero, style: .plain)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func calculateHeight() -> CGFloat {
        layoutIfNeeded()
        return tableView.contentSize.height + PickMultichainAddressPresentation.contentVerticalPadding
    }
}

private extension PickMultichainAddressUiView {
    enum Layout {
        static let horizontalInset: CGFloat = 16
    }

    func setup() {
        backgroundColor = .clear

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = PickMultichainAddressPresentation.rowHeight
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.sectionHeaderTopPadding = 0
        tableView.tableFooterView = UIView(frame: .zero)

        addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(PickMultichainAddressPresentation.contentVerticalPadding)
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.bottom.equalToSuperview()
        }
    }
}
