import SwiftUI

public struct TKTagSwiftUIViewConfig: Hashable {
    public var text: String
    public var textColor: UIColor
    public var textPadding: UIEdgeInsets
    public var backgroundColor: UIColor
    public var borderColor: UIColor
    public var backgroundPadding: UIEdgeInsets

    public init(
        text: String,
        textColor: UIColor,
        textPadding: UIEdgeInsets,
        backgroundColor: UIColor,
        borderColor: UIColor,
        backgroundPadding: UIEdgeInsets
    ) {
        self.text = text.uppercased()
        self.textColor = textColor
        self.textPadding = textPadding
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.backgroundPadding = backgroundPadding
    }

    public init(tagConfiguration: TKTagView.Configuration) {
        let textColor: UIColor = {
            if tagConfiguration.text.length > 0 {
                return tagConfiguration.text.attribute(
                    .foregroundColor,
                    at: 0,
                    effectiveRange: nil
                ) as? UIColor ?? .Text.secondary
            } else {
                return .Text.secondary
            }
        }()

        self.init(
            text: tagConfiguration.text.string,
            textColor: textColor,
            textPadding: tagConfiguration.textPadding,
            backgroundColor: tagConfiguration.backgroundColor,
            borderColor: tagConfiguration.borderColor,
            backgroundPadding: tagConfiguration.backgroundPadding
        )
    }

    public static func accentTag(
        text: String,
        color: UIColor
    ) -> TKTagSwiftUIViewConfig {
        TKTagSwiftUIViewConfig(
            text: text,
            textColor: color,
            textPadding: UIEdgeInsets(top: 2.5, left: 5, bottom: 3.5, right: 5),
            backgroundColor: color.withAlphaComponent(0.16),
            borderColor: .clear,
            backgroundPadding: UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
        )
    }

    public static func tag(text: String) -> TKTagSwiftUIViewConfig {
        TKTagSwiftUIViewConfig(
            text: text,
            textColor: .Text.secondary,
            textPadding: UIEdgeInsets(top: 2.5, left: 5, bottom: 3.5, right: 5),
            backgroundColor: .Background.contentTint,
            borderColor: .clear,
            backgroundPadding: UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
        )
    }

    public static func outlineTag(text: String) -> TKTagSwiftUIViewConfig {
        TKTagSwiftUIViewConfig(
            text: text,
            textColor: .Text.secondary,
            textPadding: UIEdgeInsets(top: 2.5, left: 5, bottom: 3.5, right: 5),
            backgroundColor: .clear,
            borderColor: .Background.contentTint,
            backgroundPadding: UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
        )
    }

    public static func outlintTag(text: String) -> TKTagSwiftUIViewConfig {
        outlineTag(text: text)
    }
}

public struct TKTagSwiftUIView: View {
    public var config: TKTagSwiftUIViewConfig

    public init(config: TKTagSwiftUIViewConfig) {
        self.config = config
    }

    public var body: some View {
        Text(config.text)
            .textStyle(.body4)
            .foregroundStyle(Color(uiColor: config.textColor))
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(config.textPadding.edgeInsets)
            .background(
                RoundedRectangle(
                    cornerRadius: Layout.cornerRadius,
                    style: .continuous
                )
                .fill(Color(uiColor: config.backgroundColor))
                .overlay(
                    RoundedRectangle(
                        cornerRadius: Layout.cornerRadius,
                        style: .continuous
                    )
                    .stroke(Color(uiColor: config.borderColor), lineWidth: Layout.borderWidth)
                )
            )
            .padding(config.backgroundPadding.edgeInsets)
            .fixedSize()
    }
}

private extension TKTagSwiftUIView {
    enum Layout {
        static let cornerRadius: CGFloat = 4
        static let borderWidth: CGFloat = 1
    }
}

private extension UIEdgeInsets {
    var edgeInsets: EdgeInsets {
        EdgeInsets(
            top: top,
            leading: left,
            bottom: bottom,
            trailing: right
        )
    }
}
