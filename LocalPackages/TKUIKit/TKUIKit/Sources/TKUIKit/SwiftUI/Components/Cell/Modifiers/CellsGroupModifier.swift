import SwiftUI

public struct CellsGroupModifier: ViewModifier {
    private let config: Config

    public init(config: Config) {
        self.config = config
    }

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
                    .fill(Color(uiColor: config.backgroundColor))
            )
            .clipShape(
                RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous)
            )
            .padding(.horizontal, config.horizontalPadding)
    }
}

public extension CellsGroupModifier {
    struct Config {
        public var horizontalPadding: CGFloat
        public var cornerRadius: CGFloat
        public var backgroundColor: UIColor

        public init(
            horizontalPadding: CGFloat = 16,
            cornerRadius: CGFloat = 16,
            backgroundColor: UIColor = .Background.content
        ) {
            self.horizontalPadding = horizontalPadding
            self.cornerRadius = cornerRadius
            self.backgroundColor = backgroundColor
        }
    }
}

public extension View {
    func asCellsGroup(config: CellsGroupModifier.Config = .init()) -> some View {
        modifier(CellsGroupModifier(config: config))
    }
}
