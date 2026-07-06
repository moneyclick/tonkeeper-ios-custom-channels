import SwiftUI

public struct SetupCellContent: Sendable, Equatable {
    public var icon: Icon
    public var title: String
    public var titleLineLimit: Int?
    public var subtitle: Subtitle?
    public var accessory: Accessory
    public var showsDivider: Bool

    public init(
        icon: Icon,
        title: String,
        titleLineLimit: Int? = nil,
        subtitle: Subtitle? = nil,
        accessory: Accessory,
        showsDivider: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.titleLineLimit = titleLineLimit
        self.subtitle = subtitle
        self.accessory = accessory
        self.showsDivider = showsDivider
    }
}

public extension SetupCellContent {
    struct Icon: Sendable, Equatable {
        public var image: UIImage
        public var tintColor: Color
        public var backgroundColor: Color

        public init(
            image: UIImage,
            tintColor: Color,
            backgroundColor: Color
        ) {
            self.image = image
            self.tintColor = tintColor
            self.backgroundColor = backgroundColor
        }
    }
}

public extension SetupCellContent {
    struct Subtitle: Sendable, Equatable {
        public var text: String
        public var color: Color
        public var textStyle: TKTextStyle
        public var lineLimit: Int?

        public init(
            text: String,
            color: Color = Color(uiColor: .Text.secondary),
            textStyle: TKTextStyle = .body2,
            lineLimit: Int? = 2
        ) {
            self.text = text
            self.color = color
            self.textStyle = textStyle
            self.lineLimit = lineLimit
        }
    }
}

public extension SetupCellContent {
    enum Accessory: Sendable, Equatable {
        case none
        case chevron
        case toggle(ToggleConfig)
    }

    struct ToggleConfig: Sendable, Equatable {
        public var isOn: Bool
        public var isEnabled: Bool

        public init(
            isOn: Bool,
            isEnabled: Bool = true
        ) {
            self.isOn = isOn
            self.isEnabled = isEnabled
        }
    }
}

public struct SetupCell: View {
    public var content: SetupCellContent
    public var onTap: (() -> Void)?
    public var onToggle: ((Bool) -> Void)?

    public init(
        content: SetupCellContent,
        onTap: (() -> Void)? = nil,
        onToggle: ((Bool) -> Void)? = nil
    ) {
        self.content = content
        self.onTap = onTap
        self.onToggle = onToggle
    }

    public var body: some View {
        Cell(
            config: Cell.Config(
                showsDivider: content.showsDivider,
                action: action
            ),
            leading: {
                CellAssetLeading {
                    SetupCellIconView(icon: content.icon)
                }
            },
            center: {
                CellCenter {
                    titleView
                } secondaryRow: {
                    if let subtitle = content.subtitle {
                        subtitleView(subtitle)
                    }
                }
            },
            trailing: {
                trailingAccessory
            }
        )
    }
}

private extension SetupCell {
    var action: (() -> Void)? {
        if case let .toggle(toggle) = content.accessory, !toggle.isEnabled {
            return nil
        }

        if let onTap {
            return onTap
        }

        guard let onToggle, case let .toggle(toggle) = content.accessory else {
            return nil
        }

        return { onToggle(!toggle.isOn) }
    }

    @ViewBuilder
    var titleView: some View {
        let text = Text(content.title)
            .textStyle(.body2)
            .foregroundStyle(Color(uiColor: .Text.primary))
            .fixedSize(horizontal: false, vertical: true)

        if let titleLineLimit = content.titleLineLimit {
            text.lineLimit(titleLineLimit)
        } else {
            text
        }
    }

    @ViewBuilder
    func subtitleView(_ subtitle: SetupCellContent.Subtitle) -> some View {
        let text = Text(subtitle.text)
            .textStyle(subtitle.textStyle)
            .foregroundStyle(subtitle.color)
            .fixedSize(horizontal: false, vertical: true)

        if let lineLimit = subtitle.lineLimit {
            text.lineLimit(lineLimit)
        } else {
            text
        }
    }

    @ViewBuilder
    var trailingAccessory: some View {
        switch content.accessory {
        case .none:
            EmptyView()
        case .chevron:
            CellTrailingAccessory(
                config: CellTrailingAccessory.Config(
                    color: .Icon.tertiary,
                    icon: Image(uiImage: .TKUIKit.Icons.Size16.chevronRight),
                    iconSize: 16
                )
            )
        case let .toggle(toggle):
            SetupCellToggleAccessory(toggle: toggle)
        }
    }
}

private struct SetupCellIconView: View {
    let icon: SetupCellContent.Icon

    var body: some View {
        Image(uiImage: icon.image)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(icon.tintColor)
            .frame(width: Layout.iconSize, height: Layout.iconSize)
            .frame(width: Layout.containerSize, height: Layout.containerSize)
            .background(icon.backgroundColor)
            .clipShape(Circle())
    }
}

private extension SetupCellIconView {
    enum Layout {
        static let containerSize: CGFloat = 44
        static let iconSize: CGFloat = 28
    }
}

private struct SetupCellToggleAccessory: View {
    let toggle: SetupCellContent.ToggleConfig

    var body: some View {
        ZStack(alignment: toggle.isOn ? .trailing : .leading) {
            Capsule()
                .fill(trackColor)
                .frame(width: Layout.trackWidth, height: Layout.trackHeight)

            Circle()
                .fill(Color(uiColor: .Background.content))
                .frame(width: Layout.thumbSize, height: Layout.thumbSize)
                .padding(Layout.thumbInset)
                .shadow(
                    color: Color.black.opacity(0.12),
                    radius: 1,
                    x: 0,
                    y: 1
                )
        }
        .opacity(toggle.isEnabled ? 1 : 0.48)
        .padding(Layout.insets)
    }

    private var trackColor: Color {
        toggle.isOn
            ? Color(uiColor: .Accent.blue)
            : Color(uiColor: .Background.contentTint)
    }
}

private extension SetupCellToggleAccessory {
    enum Layout {
        static let trackWidth: CGFloat = 51
        static let trackHeight: CGFloat = 31
        static let thumbSize: CGFloat = 27
        static let thumbInset: CGFloat = 2
        static let insets = EdgeInsets(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: 16
        )
    }
}
