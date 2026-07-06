import SwiftUI
import TKUIKit
import UIKit

struct MultichainSwapConfirmSliderRepresentable: UIViewRepresentable {
    let title: NSAttributedString
    let isEnabled: Bool
    let onConfirm: () -> Void

    func makeUIView(context: Context) -> TKSlider {
        let slider = TKSlider()
        slider.appearance = .standart
        slider.title = title
        slider.isEnable = isEnabled
        slider.didConfirm = onConfirm
        slider.swipeHandleAccessibilityIdentifier = "confirm_swipe"
        return slider
    }

    func updateUIView(_ uiView: TKSlider, context: Context) {
        uiView.title = title
        uiView.isEnable = isEnabled
        uiView.didConfirm = onConfirm
    }
}
