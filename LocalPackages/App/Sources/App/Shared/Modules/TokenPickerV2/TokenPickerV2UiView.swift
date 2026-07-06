import SnapKit
import TKUIKit
import UIKit

final class TokenPickerV2UiView: UIView {
    let tableView = UITableView(frame: .zero, style: .plain)
    let fallbackScrollView = UIScrollView()
    let placeholderHostingView = SwiftUIHostingView()

    let catalogSortOverlay = TokenPickerV2CatalogSortOverlayView()

    private let contentContainerView = UIView()
    private var isPlaceholderVisible = false
    private var catalogSortOverlayBottomInset: CGFloat = 0 {
        didSet {
            guard catalogSortOverlayBottomInset != oldValue else {
                return
            }
            updateScrollInsets()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        updateScrollInsets()
    }

    var currentScrollView: UIScrollView {
        isPlaceholderVisible ? fallbackScrollView : tableView
    }

    func setPlaceholderVisible(_ isVisible: Bool) {
        isPlaceholderVisible = isVisible
        tableView.isHidden = isVisible
        fallbackScrollView.isHidden = !isVisible
        placeholderHostingView.isHidden = !isVisible
        updateScrollInsets()
    }

    func setCatalogSortOverlayVisible(_ isVisible: Bool, title: String) {
        catalogSortOverlay.configure(visible: isVisible, title: title)
        catalogSortOverlayBottomInset = isVisible
            ? TokenPickerV2CatalogSortOverlayView.Layout.scrollContentBottomInsetWhenVisible
            : 0
    }

    func calculateHeight() -> CGFloat {
        layoutIfNeeded()

        if isPlaceholderVisible {
            let placeholderSize = placeholderHostingView.systemLayoutSizeFitting(
                CGSize(
                    width: max(bounds.width - Layout.horizontalInset * 2, 1),
                    height: UIView.layoutFittingCompressedSize.height
                ),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            return Layout.placeholderTopInset + ceil(placeholderSize.height) + scrollViewBottomInset
        }

        return tableView.contentSize.height + scrollViewBottomInset
    }
}

private extension TokenPickerV2UiView {
    enum Layout {
        static let horizontalInset: CGFloat = 16
        static let placeholderTopInset: CGFloat = 48
        static let placeholderBottomInset: CGFloat = 24
    }

    var scrollViewBottomInset: CGFloat {
        safeAreaInsets.bottom + catalogSortOverlayBottomInset
    }

    func setup() {
        backgroundColor = .clear

        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .onDrag

        fallbackScrollView.alwaysBounceVertical = false
        fallbackScrollView.showsVerticalScrollIndicator = false
        fallbackScrollView.isHidden = true
        placeholderHostingView.isHidden = true
        contentContainerView.layer.cornerRadius = 16
        contentContainerView.layer.masksToBounds = true
        contentContainerView.backgroundColor = .clear

        addSubview(contentContainerView)
        addSubview(catalogSortOverlay)
        contentContainerView.addSubview(tableView)
        contentContainerView.addSubview(fallbackScrollView)
        fallbackScrollView.addSubview(placeholderHostingView)

        contentContainerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
        }

        catalogSortOverlay.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(catalogSortOverlay.sortButton.snp.top)
                .offset(-TokenPickerV2CatalogSortOverlayView.Layout.fadeTopPadding)
        }

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        fallbackScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        placeholderHostingView.snp.makeConstraints { make in
            make.top.equalTo(fallbackScrollView.contentLayoutGuide).offset(Layout.placeholderTopInset)
            make.leading.equalTo(fallbackScrollView.contentLayoutGuide).offset(Layout.horizontalInset)
            make.trailing.equalTo(fallbackScrollView.contentLayoutGuide).inset(Layout.horizontalInset)
            make.bottom.equalTo(fallbackScrollView.contentLayoutGuide).inset(Layout.placeholderBottomInset)
            make.width.equalTo(fallbackScrollView.frameLayoutGuide).offset(-Layout.horizontalInset * 2)
            make.height.greaterThanOrEqualTo(fallbackScrollView.frameLayoutGuide)
                .offset(-(Layout.placeholderTopInset + Layout.placeholderBottomInset))
        }

        updateScrollInsets()
    }

    func updateScrollInsets() {
        let bottomInset = scrollViewBottomInset

        tableView.contentInset.bottom = bottomInset
        tableView.verticalScrollIndicatorInsets.bottom = bottomInset

        fallbackScrollView.contentInset.bottom = bottomInset
        fallbackScrollView.verticalScrollIndicatorInsets.bottom = bottomInset
    }
}
