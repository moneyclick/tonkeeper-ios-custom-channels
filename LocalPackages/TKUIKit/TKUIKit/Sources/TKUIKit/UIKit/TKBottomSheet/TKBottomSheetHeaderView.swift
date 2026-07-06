import SnapKit
import SwiftUI
import UIKit

public final class TKBottomSheetHeaderView: UIView {
    private var configuration: TKBottomSheetHeaderConfiguration?
    private var closeAction: () -> Void = {}
    private var hostingController: UIHostingController<AnyView>?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupHostingController()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        detachHostingController()
    }

    public func configure(configuration: TKBottomSheetHeaderConfiguration?) {
        self.configuration = configuration
        updateRootView()
    }

    public func setCloseAction(_ action: @escaping () -> Void) {
        closeAction = action
        updateRootView()
    }

    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        updateHostingControllerParent()
    }

    override public func didMoveToWindow() {
        super.didMoveToWindow()
        updateHostingControllerParent()
    }

    override public func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        guard let hostingView = hostingController?.view else {
            return super.systemLayoutSizeFitting(
                targetSize,
                withHorizontalFittingPriority: horizontalFittingPriority,
                verticalFittingPriority: verticalFittingPriority
            )
        }

        let fittingWidth: CGFloat = {
            if targetSize.width > 0, targetSize.width.isFinite {
                return targetSize.width
            }

            if bounds.width > 0, bounds.width.isFinite {
                return bounds.width
            }

            return UIScreen.main.bounds.width
        }()

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.setNeedsLayout()
        hostingView.layoutIfNeeded()

        let widthConstraint = hostingView.widthAnchor.constraint(equalToConstant: fittingWidth)
        widthConstraint.isActive = true

        let fittingSize = hostingView.systemLayoutSizeFitting(
            CGSize(
                width: fittingWidth,
                height: UIView.layoutFittingCompressedSize.height
            ),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        widthConstraint.isActive = false

        return CGSize(
            width: fittingWidth,
            height: ceil(fittingSize.height)
        )
    }
}

private extension TKBottomSheetHeaderView {
    func setupHostingController() {
        backgroundColor = .clear
        let hostingController = UIHostingController(rootView: AnyView(EmptyView()))
        hostingController.view.backgroundColor = .clear
        if #available(iOS 16.4, *) {
            hostingController.safeAreaRegions = []
        }
        self.hostingController = hostingController
        updateHostingControllerParent()
        updateRootView()
    }

    func updateRootView() {
        hostingController?.rootView = AnyView(
            TKBottomSheetHeaderContentView(
                configuration: configuration ?? .init(title: .empty),
                closeAction: closeAction
            )
            .ignoresSafeArea()
        )
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    func updateHostingControllerParent() {
        guard let hostingController else { return }

        let parentViewController = nearestViewController()
        if hostingController.parent === parentViewController {
            ensureHostingViewHierarchy()
            return
        }

        detachHostingController()

        guard let parentViewController else {
            return
        }

        parentViewController.addChild(hostingController)
        ensureHostingViewHierarchy()
        hostingController.didMove(toParent: parentViewController)
    }

    func ensureHostingViewHierarchy() {
        guard let hostingView = hostingController?.view else { return }
        guard hostingView.superview !== self else { return }

        hostingView.removeFromSuperview()
        addSubview(hostingView)
        hostingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func detachHostingController() {
        guard let hostingController, hostingController.parent != nil else { return }

        hostingController.willMove(toParent: nil)
        hostingController.view.removeFromSuperview()
        hostingController.removeFromParent()
    }

    func nearestViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let currentResponder = responder {
            if let viewController = currentResponder as? UIViewController {
                return viewController
            }
            responder = currentResponder.next
        }
        return nil
    }
}
