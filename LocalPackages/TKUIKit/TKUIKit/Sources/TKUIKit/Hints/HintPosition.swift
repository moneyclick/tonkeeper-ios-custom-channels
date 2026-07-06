import UIKit

public struct HintPosition: Sendable {
    public var tailParameters: HintTailParameters?
    public var horizontal: HorizontalPosition
    public var vertical: VerticalPosition
    public var direction: Direction

    public init(
        tailParameters: HintTailParameters?,
        horizontal: HorizontalPosition,
        vertical: VerticalPosition,
        direction: Direction
    ) {
        self.tailParameters = tailParameters
        self.horizontal = horizontal
        self.vertical = vertical
        self.direction = direction
    }

    var mirroredHorizontally: Self {
        Self(
            tailParameters: tailParameters,
            horizontal: horizontal.mirrored,
            vertical: vertical,
            direction: direction.mirroredHorizontally
        )
    }

    var mirroredVertically: Self {
        Self(
            tailParameters: tailParameters,
            horizontal: horizontal,
            vertical: vertical,
            direction: direction.mirroredVertically
        )
    }

    var cornerOptions: [Self] {
        [
            Self(
                tailParameters: tailParameters,
                horizontal: .relative(0),
                vertical: vertical,
                direction: direction
            ),
            Self(
                tailParameters: tailParameters,
                horizontal: .relative(1),
                vertical: vertical,
                direction: direction
            ),
        ]
    }

    public static var `default`: Self {
        Self(
            tailParameters: nil,
            horizontal: .default,
            vertical: .default,
            direction: .topRight
        )
    }
}

public extension HintPosition {
    enum HorizontalPosition: Sendable {
        /// offset from midX of the source view in where 1 is (maxX - midX), -1 is (midX - maxX)
        case relative(CGFloat)
        /// offset from midX of the source view in points
        case absolute(CGFloat)

        var mirrored: Self {
            switch self {
            case let .relative(value):
                .relative(-value)
            case let .absolute(value):
                .absolute(-value)
            }
        }

        public func absoluteValue(in frame: CGRect) -> CGFloat {
            switch self {
            case let .relative(value):
                frame.midX + frame.width * value * 0.5
            case let .absolute(value):
                frame.midX + value
            }
        }

        public static var `default`: Self {
            .relative(0)
        }
    }
}

public extension HintPosition {
    struct VerticalPosition: Sendable {
        public var absolute: CGFloat

        public init(absolute: CGFloat) {
            self.absolute = absolute
        }

        public static var `default`: Self {
            Self(absolute: 0)
        }
    }
}

public extension HintPosition {
    enum Direction: Sendable {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight

        var mirroredHorizontally: Self {
            switch self {
            case .topLeft:
                .topRight
            case .topRight:
                .topLeft
            case .bottomLeft:
                .bottomRight
            case .bottomRight:
                .bottomLeft
            }
        }

        var mirroredVertically: Self {
            switch self {
            case .topLeft:
                .bottomLeft
            case .topRight:
                .bottomRight
            case .bottomLeft:
                .topLeft
            case .bottomRight:
                .topRight
            }
        }
    }
}
