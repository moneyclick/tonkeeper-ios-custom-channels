import SwiftUI

public struct AnchorViewResolver: UIViewRepresentable {
    public var onResolveView: (UIView) -> Void

    public init(onResolveView: @escaping (UIView) -> Void) {
        self.onResolveView = onResolveView
    }

    public func makeUIView(context _: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            onResolveView(view)
        }
        return view
    }

    public func updateUIView(_ uiView: UIView, context _: Context) {
        DispatchQueue.main.async {
            onResolveView(uiView)
        }
    }
}
