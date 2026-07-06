import UIKit

extension UITabBarItem {
    var contentView: UIView? {
        value(forKey: "view") as? UIView
    }

    var firstImageView: UIImageView? {
        contentView.flatMap(\.firstImageView)
    }
}

private extension UIView {
    var firstImageView: UIImageView? {
        if let imageView = self as? UIImageView {
            return imageView
        }
        for subview in subviews {
            if let imageView = subview.firstImageView {
                return imageView
            }
        }
        return nil
    }
}
