import Lottie
import SnapKit
import TKUIKit
import UIKit

@MainActor
final class DefaultLottieTabBarController: NSObject {
    private final class LottieTabView {
        let animationView: LottieAnimationView
        weak var imageView: UIImageView?

        init(animationView: LottieAnimationView, imageView: UIImageView? = nil) {
            self.animationView = animationView
            self.imageView = imageView
        }
    }

    private weak var tabBarController: UITabBarController?
    private let animatedViews: [LottieTabView]

    init?(
        tabBarController: UITabBarController,
        items: [LottieResourceConvertible]
    ) {
        self.tabBarController = tabBarController

        let resources = items.compactMap(\.asLottieResource)
        guard resources.count == items.count else {
            return nil
        }

        self.animatedViews = resources
            .map { resource in
                let animationView = LottieAnimationView(
                    name: resource.name,
                    bundle: resource.bundle,
                    subdirectory: resource.subdirectory
                )
                animationView.loopMode = .playOnce
                animationView.contentMode = .center
                animationView.backgroundBehavior = .pauseAndRestore
                animationView.isUserInteractionEnabled = false
                animationView.isAccessibilityElement = false
                return LottieTabView(animationView: animationView)
            }

        super.init()
        installAnimationViewsIfNeeded()
        updateSelection(selectedIndex: tabBarController.selectedIndex)
    }
}

extension DefaultLottieTabBarController: LottieTabBarControlling {
    func uninstall() {
        for view in animatedViews {
            view.imageView?.isHidden = false
            view.animationView.stop()
            view.animationView.removeFromSuperview()
        }
    }

    func playAnimation(at index: Int) {
        installAnimationViewsIfNeeded()

        for animationView in animatedViews.map(\.animationView) {
            animationView.stop()
            animationView.currentProgress = 0
        }

        updateSelection(selectedIndex: index)
        animatedViews[safe: index]?.animationView.play()
    }
}

extension DefaultLottieTabBarController {
    private func installAnimationViewsIfNeeded() {
        guard let tabBarItems = tabBarController?.tabBar.items else { return }

        for (index, view) in animatedViews.enumerated() {
            guard
                let tabBarItem = tabBarItems[safe: index],
                let imageView = tabBarItem.firstImageView
            else {
                continue
            }

            let needsInstall = view.animationView.superview !== imageView.superview || view.imageView !== imageView
            guard needsInstall else { continue }

            view.animationView.removeFromSuperview()
            imageView.superview?.addSubview(view.animationView)
            view.animationView.snp.remakeConstraints { make in
                make.edges.equalTo(imageView)
            }
            imageView.isHidden = true
            view.imageView = imageView
        }
    }

    private func updateSelection(selectedIndex: Int) {
        for (index, view) in animatedViews.enumerated() {
            let color = index == selectedIndex ? UIColor.TabBar.activeIcon : UIColor.TabBar.inactiveIcon
            let valueProvider = ColorValueProvider(color.asLottieColor)

            view.animationView.setValueProvider(
                valueProvider,
                keypath: AnimationKeypath(keypath: "**.Fill 1.Color")
            )
            view.animationView.setValueProvider(
                valueProvider,
                keypath: AnimationKeypath(keypath: "**.Stroke 1.Color")
            )
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
