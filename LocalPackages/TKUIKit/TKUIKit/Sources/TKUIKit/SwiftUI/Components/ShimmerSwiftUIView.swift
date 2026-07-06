import SwiftUI
import UIKit

public struct ShimmerSwiftUIView: View {
    public var config: Config

    public init(
        config: Config = Config()
    ) {
        self.config = config
    }

    public var body: some View {
        switch config.cornerRadius {
        case let .value(radius):
            Color(uiColor: config.color)
                .clipShape(RoundedRectangle(cornerRadius: radius))
        case .capsule:
            Color(uiColor: config.color)
                .clipShape(Capsule())
        }
    }
}

public extension ShimmerSwiftUIView {
    enum CornerRadius {
        case value(CGFloat)
        case capsule
    }

    struct Config {
        public var color: UIColor
        public var cornerRadius: CornerRadius

        public init(
            color: UIColor = .Background.content,
            cornerRadius: CornerRadius = .value(12)
        ) {
            self.color = color
            self.cornerRadius = cornerRadius
        }
    }
}

#Preview {
    ShimmerSwiftUIView()
        .frame(width: 56, height: 56)
        .debugPreview()
}
