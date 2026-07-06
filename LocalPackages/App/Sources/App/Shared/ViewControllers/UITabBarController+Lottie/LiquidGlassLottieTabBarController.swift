import Lottie
import TKLogging
import TKUIKit
import UIKit

@MainActor
final class LiquidGlassLottieTabBarController: NSObject {
    private struct OriginalTabBarImages {
        let image: UIImage?
        let selectedImage: UIImage?
    }

    @MainActor
    private final class LottieTabView {
        let animationView: LottieAnimationView
        var imageView: UIImageView?

        init(animationView: LottieAnimationView, imageView: UIImageView? = nil) {
            self.animationView = animationView
            self.imageView = imageView
        }
    }

    private weak let tabBarController: UITabBarController?
    private let animatedViews: [LottieTabView]
    private var originalTabBarImages = [Int: OriginalTabBarImages]()
    private var activeAnimatedIndex: Int?
    private var animationGeneration = 0

    private lazy var interactionTrackingRecognizer = {
        let recornizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleInteractionTracking(_:))
        )
        recornizer.minimumPressDuration = 0
        recornizer.cancelsTouchesInView = false
        recornizer.delegate = self
        return recornizer
    }()

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
                return animationView
            }
            .map { animationView in
                LottieTabView(animationView: animationView)
            }
        super.init()
        setup()
    }

    private func setup() {
        installInteractionTrackingIfNeeded()
        installAnimationViewsIfNeeded()
    }
}

extension LiquidGlassLottieTabBarController: LottieTabBarControlling {
    func playAnimation(at index: Int) {
        guard let view = animatedViews[safe: index] else {
            return
        }
        animationGeneration += 1
        let generation = animationGeneration
        activeAnimatedIndex = index
        installAnimationViewsIfNeeded()
        for animationView in animatedViews.map(\.animationView) {
            animationView.stop()
            animationView.currentProgress = 0
            animationView.isHidden = true
        }
        restoreAllSystemIcons()
        updateSelection(selectedIndex: index)
        concealSystemIcon(at: index)
        view.animationView.isHidden = false
        view.animationView.play { [weak self, weak animationView = view.animationView] _ in
            guard
                let self,
                self.animationGeneration == generation,
                self.activeAnimatedIndex == index
            else {
                return
            }
            self.activeAnimatedIndex = nil
            animationView?.isHidden = true
            animationView?.currentProgress = 0
            self.restoreAllSystemIcons()
        }
    }

    func uninstall() {
        activeAnimatedIndex = nil
        animationGeneration += 1
        restoreAllSystemIcons()
        for view in animatedViews.map(\.animationView) where view.superview != nil {
            view.removeFromSuperview()
        }
        interactionTrackingRecognizer.view?.removeGestureRecognizer(interactionTrackingRecognizer)
    }
}

extension LiquidGlassLottieTabBarController {
    private func installInteractionTrackingIfNeeded() {
        guard
            let tabBar = tabBarController?.tabBar,
            interactionTrackingRecognizer.view == nil
        else {
            return
        }
        tabBar.addGestureRecognizer(interactionTrackingRecognizer)
    }

    private func installAnimationViewsIfNeeded() {
        guard
            let tabBarController,
            let rootView = tabBarController.view,
            let tabBarItems = tabBarController.tabBar.items
        else {
            return
        }
        for (index, view) in animatedViews.enumerated() {
            guard
                let tabBarItem = tabBarItems[safe: index],
                let itemView = tabBarItem.contentView
            else {
                continue
            }
            let needsToAddToRootView: Bool
            switch view.animationView.superview {
            case let .some(view) where view === rootView:
                needsToAddToRootView = false
            case .none:
                needsToAddToRootView = true
            default:
                view.animationView.removeFromSuperview()
                needsToAddToRootView = true
            }
            if needsToAddToRootView {
                rootView.addSubview(view.animationView)
                rootView.bringSubviewToFront(view.animationView)
                view.animationView.isHidden = true
            }
            if let imageView = tabBarItem.firstImageView {
                if imageView != view.imageView {
                    view.imageView = imageView
                    view.animationView.snp.remakeConstraints { make in
                        make.edges.equalTo(imageView)
                    }
                }
            } else {
                view.imageView = nil
                view.animationView.snp.remakeConstraints { make in
                    make.center.equalTo(itemView)
                    make.width.height.equalTo(28)
                }
            }
            view.animationView.isHidden = true
        }
    }

    private func updateSelection(selectedIndex: Int) {
        for (index, itemView) in animatedViews.enumerated() {
            let color = index == selectedIndex ? UIColor.TabBar.activeIconLiquidGlass : UIColor.TabBar.inactiveIcon
            let valueProvider = ColorValueProvider(color.asLottieColor)

            itemView.animationView.setValueProvider(
                valueProvider,
                keypath: AnimationKeypath(keypath: "**.Fill 1.Color")
            )
            itemView.animationView.setValueProvider(
                valueProvider,
                keypath: AnimationKeypath(keypath: "**.Stroke 1.Color")
            )
        }
    }

    private func concealSystemIcon(at index: Int) {
        guard
            let tabBarController,
            let item = tabBarController.tabBar.items?[safe: index]
        else {
            return
        }
        if originalTabBarImages[index] == nil {
            originalTabBarImages[index] = OriginalTabBarImages(
                image: item.image,
                selectedImage: item.selectedImage
            )
        }
        let placeholder = UIImage.clearTabBarPlaceholder
        item.image = placeholder
        item.selectedImage = placeholder
    }

    private func restoreAllSystemIcons() {
        guard let tabBarController else { return }
        for (index, originalImages) in originalTabBarImages {
            guard let item = tabBarController.tabBar.items?[safe: index] else { continue }
            item.image = originalImages.image
            item.selectedImage = originalImages.selectedImage
        }
    }

    @objc
    private func handleInteractionTracking(_ recognizer: UILongPressGestureRecognizer) {
        guard let tabBarController else { return }

        switch recognizer.state {
        case .began, .changed:
            let location = recognizer.location(in: tabBarController.tabBar)
            let highlightedIndex = (0 ..< animatedViews.count).first { index in
                guard
                    let itemView = tabBarController.tabBar.items?[safe: index]?.contentView
                else {
                    return false
                }
                return itemView.frame.contains(location)
            }
            updateSelection(selectedIndex: highlightedIndex ?? tabBarController.selectedIndex)
        case .ended, .cancelled, .failed:
            updateSelection(selectedIndex: tabBarController.selectedIndex)
        default:
            break
        }
    }
}

extension LiquidGlassLottieTabBarController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        gestureRecognizer === interactionTrackingRecognizer || otherGestureRecognizer === interactionTrackingRecognizer
    }
}

private extension UIImage {
    static let clearTabBarPlaceholder: UIImage = {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: CGSize(width: 28, height: 28), format: format).image { _ in }
            .withRenderingMode(.alwaysOriginal)
    }()
}
