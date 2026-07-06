import SnapKit
import UIKit

final class NetworkFeePickerUiView: UIView {
    let scrollView = UIScrollView()
    let contentHostingView = SwiftUIHostingView()

    private let contentContainerView = UIView()

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

    func calculateHeight(width: CGFloat) -> CGFloat {
        layoutIfNeeded()
        scrollView.layoutIfNeeded()

        let contentSize = contentContainerView.systemLayoutSizeFitting(
            CGSize(
                width: max(width, 1),
                height: UIView.layoutFittingCompressedSize.height
            ),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        let contentHeight = max(
            scrollView.contentSize.height,
            contentSize.height
        )

        return ceil(contentHeight) + safeAreaInsets.bottom
    }
}

private extension NetworkFeePickerUiView {
    func setup() {
        backgroundColor = .clear

        scrollView.backgroundColor = .clear
        scrollView.alwaysBounceVertical = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never

        addSubview(scrollView)
        scrollView.addSubview(contentContainerView)
        contentContainerView.addSubview(contentHostingView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentContainerView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        contentHostingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        updateScrollInsets()
    }

    func updateScrollInsets() {
        let bottomInset = safeAreaInsets.bottom
        scrollView.contentInset.bottom = bottomInset
        scrollView.verticalScrollIndicatorInsets.bottom = bottomInset
    }
}
