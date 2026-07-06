import SwiftUI

public struct NotificationBannerContent: Sendable, Equatable {
    public var title: String?
    public var description: String?
    public var state: NotificationBanner.State
    public var buttonTitle: String?
    public var showsCloseButton: Bool

    public init(
        title: String?,
        description: String?,
        state: NotificationBanner.State,
        buttonTitle: String? = nil,
        showsCloseButton: Bool = false
    ) {
        self.title = title
        self.description = description
        self.state = state
        self.buttonTitle = buttonTitle
        self.showsCloseButton = showsCloseButton
    }
}

public struct NotificationBanner: View {
    public enum State: CaseIterable, Sendable, Equatable {
        case neutral
        case neutralAlternate
        case accentOrange
        case accentRed
        case accentBlue
    }

    public var content: NotificationBannerContent
    public var onTap: (() -> Void)?
    public var onButtonTap: (() -> Void)?
    public var onCloseTap: (() -> Void)?

    public init(
        content: NotificationBannerContent,
        onTap: (() -> Void)? = nil,
        onButtonTap: (() -> Void)? = nil,
        onCloseTap: (() -> Void)? = nil
    ) {
        self.content = content
        self.onTap = onTap
        self.onButtonTap = onButtonTap
        self.onCloseTap = onCloseTap
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                if let title = content.title {
                    Text(title)
                        .textStyle(.label1)
                        .foregroundStyle(content.state.titleColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Layout.titleTopPadding)
                }

                if let description = content.description {
                    Text(description)
                        .textStyle(.body2)
                        .foregroundStyle(content.state.descriptionColor)
                        .opacity(content.state.descriptionAlpha)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Layout.subtitleTopPadding)
                }

                if let title = content.buttonTitle {
                    button(title: title)
                        .padding(.top, Layout.buttonTopPadding)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(contentInsets)

            if content.showsCloseButton {
                closeButton
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                .fill(content.state.backgroundColor)
        )
        .contentShape(
            RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
        )
        .onTapGesture {
            onTap?()
        }
    }
}

private extension NotificationBanner {
    var contentInsets: EdgeInsets {
        EdgeInsets(
            top: Layout.topPadding,
            leading: Layout.horizontalPadding,
            bottom: Layout.bottomPadding,
            trailing: content.showsCloseButton
                ? Layout.trailingPaddingWithCloseButton
                : Layout.horizontalPadding
        )
    }

    func button(title: String) -> some View {
        Button {
            onButtonTap?()
        } label: {
            HStack(spacing: Layout.buttonIconSpacing) {
                Text(title)
                    .textStyle(.label2)

                Image(uiImage: .TKUIKit.Icons.Size12.chevronRight)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Layout.buttonIconSize, height: Layout.buttonIconSize)
                    .padding([.top, .leading], 1)
            }
            .foregroundStyle(content.state.buttonColor)
        }
        .buttonStyle(NotificationBannerButtonStyle())
    }

    var closeButton: some View {
        Button {
            onCloseTap?()
        } label: {
            Image(uiImage: .TKUIKit.Icons.Size16.close)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: Layout.closeIconSize, height: Layout.closeIconSize)
                .foregroundStyle(content.state.closeColor)
                .frame(
                    width: Layout.closeHitSize,
                    height: Layout.closeHitSize,
                    alignment: .topTrailing
                )
        }
        .buttonStyle(NotificationBannerButtonStyle())
        .padding(.top, Layout.closeButtonTopPadding)
        .padding(.trailing, Layout.closeButtonTrailingPadding)
    }
}

private struct NotificationBannerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.48 : 1)
    }
}

private extension NotificationBanner.State {
    var titleColor: Color {
        switch self {
        case .neutral, .neutralAlternate:
            Color(uiColor: .Text.primary)
        case .accentOrange:
            Color(uiColor: .Constant.black)
        case .accentRed, .accentBlue:
            Color(uiColor: .Constant.white)
        }
    }

    var descriptionColor: Color {
        switch self {
        case .neutral, .neutralAlternate:
            Color(uiColor: .Text.secondary)
        case .accentOrange:
            Color(uiColor: .Constant.black)
        case .accentRed, .accentBlue:
            Color(uiColor: .Constant.white)
        }
    }

    var buttonColor: Color {
        switch self {
        case .neutral, .neutralAlternate:
            Color(uiColor: .Text.primary)
        case .accentOrange:
            Color(uiColor: .Constant.black)
        case .accentRed, .accentBlue:
            Color(uiColor: .Constant.white)
        }
    }

    var closeColor: Color {
        switch self {
        case .neutral, .neutralAlternate:
            Color(uiColor: .Icon.primary)
        case .accentOrange:
            Color(uiColor: .Constant.black)
        case .accentRed, .accentBlue:
            Color(uiColor: .Constant.white)
        }
    }

    var backgroundColor: Color {
        switch self {
        case .neutral:
            Color(uiColor: .Background.contentTint)
        case .neutralAlternate:
            Color(uiColor: .Background.content)
        case .accentOrange:
            Color(uiColor: .Accent.orange)
        case .accentRed:
            Color(uiColor: .Accent.red)
        case .accentBlue:
            Color(uiColor: .Accent.blue)
        }
    }

    var descriptionAlpha: CGFloat {
        switch self {
        case .neutral, .neutralAlternate:
            1
        case .accentOrange, .accentRed, .accentBlue:
            0.76
        }
    }
}

private extension NotificationBanner {
    enum Layout {
        static let cornerRadius: CGFloat = 16
        static let topPadding: CGFloat = 12
        static let bottomPadding: CGFloat = 14
        static let horizontalPadding: CGFloat = 16
        static let trailingPaddingWithCloseButton: CGFloat = 48

        static let titleTopPadding: CGFloat = 3
        static let subtitleTopPadding: CGFloat = 3

        static let buttonTopPadding: CGFloat = 6
        static let buttonIconSpacing: CGFloat = 2
        static let buttonIconSize: CGFloat = 12
        static let closeIconSize: CGFloat = 16
        static let closeHitSize: CGFloat = 44
        static let closeButtonTopPadding: CGFloat = 16
        static let closeButtonTrailingPadding: CGFloat = 16
    }
}
