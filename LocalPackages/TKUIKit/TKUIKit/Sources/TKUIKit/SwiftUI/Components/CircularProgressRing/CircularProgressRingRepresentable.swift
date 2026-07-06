import SwiftUI
import UIKit

public struct CircularProgressRingRepresentable: UIViewRepresentable {
    public var duration: TimeInterval
    public var onComplete: () -> Void
    public var restartToken: Int
    public var lineWidth: CGFloat
    public var backgroundFillColor: UIColor

    public init(
        duration: TimeInterval = 10,
        onComplete: @escaping () -> Void = {},
        restartToken: Int = 0,
        lineWidth: CGFloat = 3,
        backgroundFillColor: UIColor = .Background.page
    ) {
        self.duration = duration
        self.onComplete = onComplete
        self.restartToken = restartToken
        self.lineWidth = lineWidth
        self.backgroundFillColor = backgroundFillColor
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeUIView(context: Context) -> CircularProgressRingView {
        CircularProgressRingView()
    }

    public func updateUIView(_ uiView: CircularProgressRingView, context: Context) {
        uiView.duration = duration
        uiView.lineWidth = lineWidth
        uiView.backgroundFillColor = backgroundFillColor
        context.coordinator.onComplete = onComplete
        uiView.onComplete = { [weak coordinator = context.coordinator] in
            coordinator?.onComplete()
        }

        let coordinator = context.coordinator
        if coordinator.lastAppliedRestartToken != restartToken {
            coordinator.lastAppliedRestartToken = restartToken
            uiView.reset()
            uiView.start()
        }
    }

    public static func dismantleUIView(_ uiView: CircularProgressRingView, coordinator: Coordinator) {
        uiView.reset()
    }

    public final class Coordinator {
        var lastAppliedRestartToken: Int?
        var onComplete: () -> Void = {}
    }
}
