import SwiftUI
import TKUIKit
import UIKit

final class PriceImpactViewController: GenericViewViewController<PriceImpactUiView>, TKBottomSheetScrollContentViewController {
    var didUpdateHeight: (() -> Void)?
    var didUpdateHeaderConfiguration: ((TKBottomSheetHeaderConfiguration?) -> Void)?
    var headerConfiguration: TKBottomSheetHeaderConfiguration? {
        nil
    }

    var scrollView: UIScrollView {
        customView.scrollView
    }

    private let presentation: PriceImpactPresentation

    init(presentation: PriceImpactPresentation) {
        self.presentation = presentation
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        render()
    }

    func calculateHeight(withWidth width: CGFloat) -> CGFloat {
        customView.calculateHeight(width: width)
    }
}

private extension PriceImpactViewController {
    func render() {
        customView.contentHostingView.setContent {
            PriceImpactView(presentation: presentation)
        }
        customView.layoutIfNeeded()
        didUpdateHeight?()
    }
}
