import SwiftUI

public struct WalletButtonConfig: Hashable {
    public enum Icon: Hashable {
        case emoji(String)
        case image(UIImage?)
    }

    public var title: String
    public var icon: Icon
    public var color: UIColor

    public init(
        title: String,
        icon: Icon,
        color: UIColor
    ) {
        self.title = title
        self.icon = icon
        self.color = color
    }
}

public struct WalletButton: View {
    public var config: WalletButtonConfig
    private let action: () -> Void

    public init(
        config: WalletButtonConfig,
        action: @escaping () -> Void
    ) {
        self.config = config
        self.action = action
    }

    public var body: some View {
        SwiftUI.Button(action: action) {
            content
        }
        .buttonStyle(
            WalletButtonStyle(
                backgroundColor: backgroundColor
            )
        )
        .accessibilityLabel(config.title)
    }
}

private extension WalletButton {
    var content: some View {
        HStack(spacing: 0) {
            iconView

            Text(config.title)
                .textStyle(Layout.titleTextStyle)
                .foregroundStyle(Color(uiColor: foregroundColor))
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.leading, Layout.iconTitleSpacing)

            Image(uiImage: .TKUIKit.Icons.Size16.chevronDown)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(
                    Color(uiColor: foregroundColor)
                        .opacity(Layout.chevronOpacity)
                )
                .frame(
                    width: Layout.chevronSize,
                    height: Layout.chevronSize
                )
                .padding(.leading, Layout.titleChevronSpacing)
        }
        .padding(Layout.contentInsets)
    }

    @ViewBuilder
    var iconView: some View {
        switch config.icon {
        case let .emoji(emoji):
            Text(emoji)
                .font(Layout.emojiFont)
                .lineLimit(1)
        case let .image(image):
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color(uiColor: foregroundColor))
                    .frame(
                        width: Layout.iconSize,
                        height: Layout.iconSize
                    )
            } else {
                Color.clear
                    .frame(
                        width: Layout.iconSize,
                        height: Layout.iconSize
                    )
            }
        }
    }

    var backgroundColor: UIColor {
        UIApplication.useSystemBarsAppearance ? .clear : config.color
    }

    var foregroundColor: UIColor {
        UIApplication.useSystemBarsAppearance ? .Text.primary : .white
    }
}

private struct WalletButtonStyle: SwiftUI.ButtonStyle {
    var backgroundColor: UIColor

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Capsule()
                    .fill(Color(uiColor: backgroundColor))
                    .opacity(configuration.isPressed ? WalletButton.Layout.highlightedOpacity : 1)
            )
            .contentShape(Capsule())
    }
}

extension WalletButton {
    enum Layout {
        static let contentInsets = EdgeInsets(
            top: 10,
            leading: 11,
            bottom: 10,
            trailing: 12
        )
        static let iconSize: CGFloat = 20
        static let chevronSize: CGFloat = 16
        static let iconTitleSpacing: CGFloat = 5
        static let titleChevronSpacing: CGFloat = 6
        static let chevronOpacity: CGFloat = 0.64
        static let highlightedOpacity: CGFloat = 0.88
        static let titleTextStyle: TKTextStyle = .label2
        static let emojiFont: Font = .system(size: 17)
    }
}
