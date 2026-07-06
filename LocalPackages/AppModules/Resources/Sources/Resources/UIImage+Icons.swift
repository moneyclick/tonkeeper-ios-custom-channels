import UIKit

public extension UIImage {
    enum Resources {
        public enum Icons {
            public enum Size28 {
                public static var bell: UIImage {
                    .imageWithName("Icons/28/ic-bell-28")
                        .withRenderingMode(.alwaysTemplate)
                }

                public static var donemark: UIImage {
                    .imageWithName("Icons/28/ic-donemark-28")
                        .withRenderingMode(.alwaysTemplate)
                }

                public static var shoppingBag: UIImage {
                    .imageWithName("Icons/28/ic-shopping-bag-28")
                        .withRenderingMode(.alwaysTemplate)
                }

                public static var swapHorizontalAlternative: UIImage {
                    .imageWithName("Icons/28/ic-swap-horizontal-alternative-28")
                        .withRenderingMode(.alwaysTemplate)
                }

                public static var trayArrowDown: UIImage {
                    .imageWithName("Icons/28/ic-tray-arrow-down-28")
                        .withRenderingMode(.alwaysTemplate)
                }

                public static var trayArrowUp: UIImage {
                    .imageWithName("Icons/28/ic-tray-arrow-up-28")
                        .withRenderingMode(.alwaysTemplate)
                }

                public static var xmark: UIImage {
                    .imageWithName("Icons/28/ic-xmark-28")
                        .withRenderingMode(.alwaysTemplate)
                }
            }

            public enum Vector {
                public static var gram: UIImage {
                    .imageWithName("Icons/Vector/gram")
                }
            }
        }
    }
}

private extension UIImage {
    static func imageWithName(_ name: String) -> UIImage {
        return UIImage(named: name, in: .module, with: nil) ?? UIImage()
    }
}
