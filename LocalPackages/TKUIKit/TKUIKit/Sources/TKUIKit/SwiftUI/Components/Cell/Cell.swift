import SwiftUI
import UIKit

public struct Cell<Leading: View, Center: View, Trailing: View>: View {
    private let config: Config
    private let leading: Leading
    private let center: Center
    private let trailing: Trailing

    init(
        config: Config,
        leading: Leading,
        center: Center,
        trailing: Trailing
    ) {
        self.config = config
        self.leading = leading
        self.center = center
        self.trailing = trailing
    }

    public var body: some View {
        if let action = config.action {
            Button(action: action) {
                content()
            }
            .buttonStyle(
                CellButtonModifier { isPressed in
                    content(isPressed: isPressed)
                }
            )
        } else {
            content()
        }
    }

    private func content(isPressed: Bool = false) -> some View {
        HStack(alignment: config.verticalAlignment, spacing: 0) {
            leading

            center
                .frame(maxWidth: .infinity, alignment: .leading)

            trailing
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isPressed
                ? config.style.highlightedBackgroundColor
                : config.style.backgroundColor
        )
        .overlay {
            if config.showsDivider && !isPressed {
                VStack {
                    Spacer(minLength: 0)
                    Rectangle()
                        .fill(config.style.separatorColor)
                        .frame(height: TKUIKit.Constants.separatorWidth)
                        .padding(.leading, config.style.dividerLeadingInset)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .contentShape(Rectangle())
    }
}

public extension Cell {
    struct Config {
        public var style: Style
        public var showsDivider: Bool
        public var verticalAlignment: VerticalAlignment
        public var action: (() -> Void)?

        public init(
            style: Style = .regular,
            showsDivider: Bool = false,
            verticalAlignment: VerticalAlignment = .center,
            action: (() -> Void)? = nil
        ) {
            self.style = style
            self.showsDivider = showsDivider
            self.verticalAlignment = verticalAlignment
            self.action = action
        }
    }

    struct Style {
        public var dividerLeadingInset: CGFloat
        public var backgroundColor: Color
        public var highlightedBackgroundColor: Color
        public var separatorColor: Color

        public init(
            dividerLeadingInset: CGFloat,
            backgroundColor: Color = Color(uiColor: .Background.content),
            highlightedBackgroundColor: Color = Color(uiColor: .Background.highlighted),
            separatorColor: Color = Color(uiColor: .Separator.common)
        ) {
            self.dividerLeadingInset = dividerLeadingInset
            self.backgroundColor = backgroundColor
            self.highlightedBackgroundColor = highlightedBackgroundColor
            self.separatorColor = separatorColor
        }

        public static var regular: Style {
            Style(
                dividerLeadingInset: 16
            )
        }

        public static var grouped: Style {
            Style(
                dividerLeadingInset: 16,
                backgroundColor: .clear,
                highlightedBackgroundColor: Color(uiColor: .Background.highlighted)
            )
        }

        public static var clear: Style {
            Style(
                dividerLeadingInset: 0,
                backgroundColor: .clear,
                highlightedBackgroundColor: .clear
            )
        }
    }
}
