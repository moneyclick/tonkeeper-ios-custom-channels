import SwiftUI

public struct CellCenterSecondaryRow: View {
    private let config: Config

    public init(config: Config) {
        self.config = config
    }

    public var body: some View {
        switch config {
        case let .content(content):
            contentView(content)
        case let .shimmer(primaryWidth):
            shimmerView(primaryWidth: primaryWidth)
        }
    }

    private func contentView(_ content: Content) -> some View {
        HStack(spacing: 0) {
            if let value = content.value {
                Text(value.title)
                    .textStyle(value.textStyle)
                    .foregroundStyle(Color(uiColor: value.textColor))
                    .lineLimit(value.lineLimit)
                    .truncationMode(value.truncationMode)
            }
            if let delta = content.delta {
                Text(delta.text)
                    .textStyle(delta.textStyle)
                    .foregroundStyle(delta.color)
                    .padding(.leading, 6)
            }
            Spacer(minLength: 0)
            if let accessory = content.accessory {
                Text(accessory.title)
                    .textStyle(accessory.textStyle)
                    .foregroundStyle(accessory.color)
                    .lineLimit(accessory.lineLimit)
                    .truncationMode(accessory.truncationMode)
            }
        }
    }

    private func shimmerView(primaryWidth: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                ShimmerSwiftUIView(
                    config: ShimmerSwiftUIView.Config(
                        color: .Background.contentTint,
                        cornerRadius: .capsule
                    )
                )
                .frame(width: primaryWidth, height: 12)
                Spacer(minLength: 0)
            }
            .frame(height: Self.defaultValueTextStyle.lineHeight)
            .padding(.vertical, -1)
        }
    }

    private static var defaultValueTextStyle: TKTextStyle {
        .body2
    }

    private static var defaultDeltaTextStyle: TKTextStyle {
        .body2
    }
}

public extension CellCenterSecondaryRow {
    struct ValueConfig {
        public var title: String
        public var textStyle: TKTextStyle
        public var lineLimit: Int
        public var textColor: UIColor
        public var truncationMode: Text.TruncationMode

        public init(
            title: String,
            textStyle: TKTextStyle? = nil,
            lineLimit: Int = 1,
            textColor: UIColor = .Text.secondary,
            truncationMode: Text.TruncationMode = .tail
        ) {
            self.title = title
            self.textStyle = textStyle ?? defaultValueTextStyle
            self.lineLimit = lineLimit
            self.textColor = textColor
            self.truncationMode = truncationMode
        }
    }

    struct AccessoryConfig {
        public var title: String
        public var textStyle: TKTextStyle
        public var color: Color
        public var lineLimit: Int
        public var truncationMode: Text.TruncationMode

        init(
            title: String,
            textStyle: TKTextStyle = .body2,
            color: Color = Color(uiColor: .Text.secondary),
            lineLimit: Int = 1,
            truncationMode: Text.TruncationMode = .tail
        ) {
            self.title = title
            self.textStyle = textStyle
            self.color = color
            self.lineLimit = lineLimit
            self.truncationMode = truncationMode
        }
    }

    struct Delta {
        public var text: String
        public var textStyle: TKTextStyle
        public var color: Color

        public init(
            text: String,
            textStyle: TKTextStyle? = nil,
            isPositive: Bool
        ) {
            self.text = text
            self.textStyle = textStyle ?? defaultDeltaTextStyle
            self.color = Color(
                uiColor: isPositive ? .Accent.green : .Accent.red
            )
        }

        public init(
            text: String,
            textStyle: TKTextStyle? = nil,
            color: Color
        ) {
            self.text = text
            self.textStyle = textStyle ?? defaultDeltaTextStyle
            self.color = color
        }
    }

    enum Config {
        case content(Content)
        case shimmer(primaryWidth: CGFloat = 170)
    }

    struct Content {
        public var value: ValueConfig?
        public var delta: Delta?
        public var accessory: AccessoryConfig?

        public init(
            value: ValueConfig? = nil,
            delta: Delta? = nil,
            accessory: AccessoryConfig? = nil
        ) {
            self.value = value
            self.delta = delta
            self.accessory = accessory
        }
    }
}
