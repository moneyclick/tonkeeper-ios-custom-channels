import SwiftUI

public struct ShimmerModifier: ViewModifier {
    private let enabled: Bool
    private let config: ShimmerSwiftUIView.Config

    public init(
        enabled: Bool,
        config: ShimmerSwiftUIView.Config
    ) {
        self.enabled = enabled
        self.config = config
    }

    public func body(content: Content) -> some View {
        content
            .opacity(enabled ? 0 : 1)
            .overlay {
                if enabled {
                    ShimmerSwiftUIView(config: config)
                }
            }
    }
}

public extension View {
    func shimmer(_ shimmer: Bool, config: ShimmerSwiftUIView.Config = .init()) -> some View {
        modifier(ShimmerModifier(enabled: shimmer, config: config))
    }
}
