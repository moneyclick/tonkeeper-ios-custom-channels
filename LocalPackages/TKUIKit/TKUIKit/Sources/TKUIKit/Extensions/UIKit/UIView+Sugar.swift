import UIKit

public extension UIView {
    func addSubviews(_ views: UIView...) {
        views.forEach { addSubview($0) }
    }

    func removeSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
    }

    func heightThatFits(_ height: CGFloat) -> CGFloat {
        return sizeThatFits(CGSize(width: bounds.width, height: height)).height
    }

    var isReachableByUser: Bool {
        guard let window else {
            return false
        }

        let boundsCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        let centerInWindow = convert(boundsCenter, to: window)
        guard let hitView = window.hitTest(centerInWindow, with: nil) else {
            return false
        }

        return hitView === self || hitView.isDescendant(of: self)
    }
}
