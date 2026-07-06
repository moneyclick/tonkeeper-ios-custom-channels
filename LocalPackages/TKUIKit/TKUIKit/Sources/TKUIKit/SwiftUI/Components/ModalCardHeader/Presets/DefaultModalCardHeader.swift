import SwiftUI

public struct DefaultModalCardHeader: View {
    var config: Config

    @State private var rightButtonAnchorView: UIView?
    @State private var leftButtonAnchorView: UIView?

    public init(config: Config) {
        self.config = config
    }

    public var body: some View {
        Group {
            switch config.height {
            case .compact:
                content
            case let .atLeast(minHeight):
                content
                    .frame(height: minHeight)
            }
        }
        .background(Color(uiColor: .Background.page))
    }

    private var content: some View {
        VStack(spacing: 0) {
            ModalCardHeader(
                config: ModalCardHeader.Config(
                    alignment: config.title.alignment
                )
            ) {
                if let icon = config.leftIcon {
                    Button {
                        icon.onTap(leftButtonAnchorView)
                    } label: {
                        iconView(config: icon)
                    }
                    .padding(.top, Layout.iconTopPadding)
                    .background(
                        AnchorViewResolver { view in
                            leftButtonAnchorView = view
                        }
                    )
                } else {
                    EmptyView()
                }
            } center: {
                if let subtitle = config.subtitle {
                    VStack(spacing: 0) {
                        titleView
                            .padding(.top, Layout.titleTopPaddingCompact)
                        if let onTap = subtitle.onTap {
                            Button {
                                onTap()
                            } label: {
                                subtitleView(subtitle: subtitle)
                            }
                            .buttonStyle(.plain)
                        } else {
                            subtitleView(subtitle: subtitle)
                        }
                        Spacer(minLength: 0)
                    }
                } else {
                    titleView
                        .padding(.top, Layout.titleTopPaddingRegular)
                }
            } trailing: {
                if let icon = config.rightIcon {
                    Button {
                        icon.onTap(rightButtonAnchorView)
                    } label: {
                        iconView(config: icon)
                    }
                    .padding(.top, Layout.iconTopPadding)
                    .background(
                        AnchorViewResolver { view in
                            rightButtonAnchorView = view
                        }
                    )
                } else {
                    EmptyView()
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Layout.horizontalInset)
    }

    private var titleView: some View {
        Text(config.title.text)
            .textStyle(.h3)
            .foregroundStyle(Color(uiColor: .Text.primary))
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: config.title.alignment.swiftUiAlignment)
    }

    private func subtitleView(subtitle: Subtitle) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: Layout.subtitleElementsPadding) {
                Spacer(minLength: 0)
                Text(subtitle.text)
                    .textStyle(.body2)
                    .foregroundStyle(Color(uiColor: subtitle.color))
                if let icon = subtitle.icon {
                    Image(uiImage: icon.image)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color(uiColor: subtitle.color))
                        .frame(width: icon.size, height: icon.size)
                        .padding(.top, icon.topPadding)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 3)
            Spacer(minLength: 0)
        }
    }

    private func iconView(
        config: Icon
    ) -> some View {
        Image(uiImage: config.image)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(
                width: config.size,
                height: config.size
            )
            .foregroundStyle(Color(uiColor: .Button.secondaryForeground))
            .padding(config.padding)
            .background(Color(uiColor: .Button.secondaryBackground))
            .clipShape(Circle())
    }
}

public extension DefaultModalCardHeader {
    enum Height {
        case compact
        case atLeast(CGFloat)
    }

    struct Icon {
        public var image: UIImage
        public var size: CGFloat
        public var padding: CGFloat
        public var onTap: (_ sourceView: UIView?) -> Void

        public init(
            image: UIImage,
            size: CGFloat,
            padding: CGFloat,
            onTap: @escaping (_ sourceView: UIView?) -> Void
        ) {
            self.image = image
            self.size = size
            self.padding = padding
            self.onTap = onTap
        }

        public static func close(onTap: @escaping (_ sourceView: UIView?) -> Void = { _ in }) -> Icon {
            Icon(
                image: .TKUIKit.Icons.Size16.close,
                size: 16,
                padding: 8,
                onTap: onTap
            )
        }
    }

    struct Title {
        public var text: String
        public var alignment: ModalCardHeaderContentAlignment

        public init(
            text: String,
            alignment: ModalCardHeaderContentAlignment = .center
        ) {
            self.text = text
            self.alignment = alignment
        }

        public static var empty: Title {
            Title(text: "")
        }
    }

    struct SubtitleIcon {
        public var image: UIImage
        public var size: CGFloat
        public var topPadding: CGFloat

        public init(image: UIImage, size: CGFloat, topPadding: CGFloat) {
            self.image = image
            self.size = size
            self.topPadding = topPadding
        }
    }

    struct Subtitle {
        public var text: String
        public var color: UIColor
        public var icon: SubtitleIcon?
        public var onTap: (() -> Void)?

        public init(
            text: String,
            color: UIColor,
            icon: SubtitleIcon? = nil,
            onTap: (() -> Void)? = nil
        ) {
            self.text = text
            self.color = color
            self.icon = icon
            self.onTap = onTap
        }
    }

    struct Config {
        public var leftIcon: Icon?
        public var title: Title
        public var subtitle: Subtitle?
        public var rightIcon: Icon?
        public var height: Height

        public init(
            leftIcon: Icon? = nil,
            title: Title = .empty,
            subtitle: Subtitle? = nil,
            rightIcon: Icon? = nil,
            height: Height? = nil
        ) {
            self.leftIcon = leftIcon
            self.title = title
            self.subtitle = subtitle
            self.rightIcon = rightIcon
            self.height = height ?? .atLeast(Layout.minHeight)
        }
    }
}

extension DefaultModalCardHeader {
    enum Layout {
        static let horizontalInset: CGFloat = 16
        static let titleTopPaddingRegular: CGFloat = 20
        static let titleTopPaddingCompact: CGFloat = 8
        static let subtitleElementsPadding: CGFloat = 4

        static let iconTopPadding: CGFloat = 16
        static let minHeight: CGFloat = 64
    }
}
