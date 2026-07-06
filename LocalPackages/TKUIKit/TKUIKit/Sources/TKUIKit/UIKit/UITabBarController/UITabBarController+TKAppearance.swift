import UIKit

public extension UITabBarController {
    func configureAppearance(isSeparatorVisible: Bool = true) {
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.titleTextAttributes = [.font: TKTextStyle.label3.font,
                                                     .foregroundColor: UIColor.TabBar.inactiveIcon]
        itemAppearance.normal.iconColor = .TabBar.inactiveIcon
        let selectedColor: UIColor = UIApplication.useSystemBarsAppearance ? .TabBar.activeIconLiquidGlass : .TabBar.activeIcon
        itemAppearance.selected.titleTextAttributes = [.font: TKTextStyle.label3.font,
                                                       .foregroundColor: selectedColor]
        itemAppearance.selected.iconColor = selectedColor

        func createTabBarAppearance() -> UITabBarAppearance {
            let appearance = UITabBarAppearance()
            if UIApplication.useSystemBarsAppearance {
                appearance.configureWithDefaultBackground()
            } else {
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = .Background.page
                appearance.shadowColor = isSeparatorVisible ? .Separator.common : .clear
            }
            appearance.stackedLayoutAppearance = itemAppearance
            return appearance
        }

        let tabBarAppearance = createTabBarAppearance()
        tabBar.standardAppearance = tabBarAppearance
        if !UIApplication.useSystemBarsAppearance {
            tabBar.isTranslucent = false
        }

        if #available(iOS 15.0, *) {
            if UIApplication.useSystemBarsAppearance {
                let scrollEdgeAppearance = createTabBarAppearance()
                scrollEdgeAppearance.shadowColor = .clear
                tabBar.scrollEdgeAppearance = scrollEdgeAppearance
            } else {
                tabBar.scrollEdgeAppearance = tabBarAppearance
            }
        }
    }
}
