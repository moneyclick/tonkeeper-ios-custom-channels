import SnapKit
import TKUIKit
import UIKit

final class TokenPickerV2CatalogSortOverlayView: UIView {
    enum Layout {
        static let bottomMargin: CGFloat = 12
        static let fadeTopPadding: CGFloat = 16
        static let sortButtonHeight: CGFloat = 36
        static var scrollContentBottomInsetWhenVisible: CGFloat {
            bottomMargin + sortButtonHeight + 16
        }
    }

    let sortButton: TKButton

    private let fadeView: TKGradientView = {
        let view = TKGradientView(color: .Background.page, direction: .bottomToTop)
        view.isUserInteractionEnabled = false
        return view
    }()

    var tapHandler: (() -> Void)? {
        didSet {
            syncTapAction()
        }
    }

    override init(frame: CGRect) {
        sortButton = Self.makeSortButton()
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(visible: Bool, title: String) {
        isHidden = !visible
        var configuration = sortButton.configuration
        configuration.content.title = .plainString(title)
        sortButton.configuration = configuration
        sortButton.accessibilityLabel = title
    }

    private func setup() {
        backgroundColor = .clear
        isHidden = true

        addSubview(fadeView)
        addSubview(sortButton)

        fadeView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        sortButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide).inset(Layout.bottomMargin)
        }

        syncTapAction()
    }

    private func syncTapAction() {
        var configuration = sortButton.configuration
        configuration.action = { [weak self] in
            self?.tapHandler?()
        }
        sortButton.configuration = configuration
    }

    private static func makeSortButton() -> TKButton {
        var configuration = TKButton.Configuration.actionButtonConfiguration(
            category: .tertiary,
            size: .small
        )
        configuration.content = TKButton.Configuration.Content(
            title: .plainString(""),
            icon: .TKUIKit.Icons.Size16.swapVertical
        )
        configuration.iconTintColor = .Icon.secondary
        configuration.spacing = 8
        configuration.contentPadding = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        configuration.iconPosition = .right
        return TKButton(configuration: configuration)
    }
}
