import SwiftUI

public struct CellCenterPrimaryRow: View {
    private let config: Config

    public init(config: Config) {
        self.config = config
    }

    public var body: some View {
        switch config {
        case let .content(content):
            contentView(content)
        case let .shimmer(primaryWidth, secondaryWidth):
            shimmerView(primaryWidth: primaryWidth, secondaryWidth: secondaryWidth)
        }
    }

    private func contentView(_ content: Content) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Text(content.title.text)
                .textStyle(content.title.style)
                .foregroundStyle(content.title.color)
                .lineLimit(1)

            if !content.tags.isEmpty {
                ForEach(Array(content.tags.enumerated()), id: \.offset) { _, tag in
                    TKTagSwiftUIView(config: tag)
                }
            }

            if let status = content.status {
                statusIconView(status: status)
                    .padding(.leading, 6)
            }
            Spacer(minLength: 0)
            if let value = content.value {
                Text(value.title)
                    .textStyle(value.style)
                    .foregroundStyle(value.color)
                    .lineLimit(1)
            }
        }
    }

    private func shimmerView(primaryWidth: CGFloat, secondaryWidth: CGFloat?) -> some View {
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
            .frame(height: Self.defaultTitleTextStyle.lineHeight)
            .padding(.vertical, -1)
            Spacer(minLength: 0)
            if let secondaryWidth {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    ShimmerSwiftUIView(
                        config: ShimmerSwiftUIView.Config(
                            color: .Background.contentTint,
                            cornerRadius: .capsule
                        )
                    )
                    .frame(width: secondaryWidth, height: 12)
                    Spacer(minLength: 0)
                }
                .frame(height: Self.defaultValueTextStyle.lineHeight)
                .padding(.vertical, -1)
            }
        }
    }

    private func statusIconView(status: StatusIcon) -> some View {
        Image(uiImage: status.image)
            .resizable()
            .scaledToFit()
            .foregroundStyle(status.color)
            .frame(width: status.size, height: status.size)
    }

    private static var defaultTitleTextStyle: TKTextStyle {
        .label1
    }

    private static var defaultValueTextStyle: TKTextStyle {
        .label1
    }
}

public extension CellCenterPrimaryRow {
    struct TitleConfig {
        public var text: String
        public var color: Color
        public var style: TKTextStyle

        public init(
            text: String,
            color: Color = Color(uiColor: .Text.primary),
            style: TKTextStyle? = nil
        ) {
            self.text = text
            self.color = color
            self.style = style ?? defaultTitleTextStyle
        }
    }

    struct ValueConfig {
        public var title: AttributedString
        public var color: Color
        public var style: TKTextStyle

        public init(
            title: String,
            color: Color = Color(uiColor: .Text.primary),
            style: TKTextStyle? = nil
        ) {
            self.title = {
                var value = AttributedString(title)
                value.foregroundColor = color
                return value
            }()
            self.color = color
            self.style = style ?? defaultValueTextStyle
        }

        public init(
            title: AttributedString,
            color: Color = Color(uiColor: .Text.primary),
            style: TKTextStyle? = nil
        ) {
            self.title = title
            self.color = color
            self.style = style ?? defaultValueTextStyle
        }
    }

    struct StatusIcon {
        public var image: UIImage
        public var color: Color
        public var size: CGFloat

        public init(
            image: UIImage,
            color: Color = Color(uiColor: .Icon.tertiary),
            size: CGFloat
        ) {
            self.image = image
            self.color = color
            self.size = size
        }
    }

    enum Config {
        case content(Content)
        case shimmer(primaryWidth: CGFloat = 65, secondaryWidth: CGFloat? = 41)
    }

    struct Content {
        public var title: TitleConfig
        public var tags: [TKTagSwiftUIViewConfig]
        public var status: StatusIcon?
        public var value: ValueConfig?

        public init(
            title: TitleConfig,
            tags: [TKTagSwiftUIViewConfig]? = nil,
            status: StatusIcon? = nil,
            value: ValueConfig? = nil
        ) {
            self.title = title
            self.tags = tags ?? []
            self.status = status
            self.value = value
        }

        public init(
            title: String,
            tags: [TKTagSwiftUIViewConfig]? = nil,
            status: StatusIcon? = nil,
            value: ValueConfig? = nil
        ) {
            self.title = TitleConfig(text: title)
            self.tags = tags ?? []
            self.status = status
            self.value = value
        }
    }
}
