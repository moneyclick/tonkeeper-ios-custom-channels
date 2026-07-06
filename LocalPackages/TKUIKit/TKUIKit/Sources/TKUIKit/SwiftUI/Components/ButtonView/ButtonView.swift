import SwiftUI

private struct ModernButtonPreviewStateKey: EnvironmentKey {
    static let defaultValue: ButtonView.State? = nil
}

private extension EnvironmentValues {
    var modernButtonPreviewState: ButtonView.State? {
        get { self[ModernButtonPreviewStateKey.self] }
        set { self[ModernButtonPreviewStateKey.self] = newValue }
    }
}

extension View {
    func modernButtonPreviewState(_ state: ButtonView.State?) -> some View {
        environment(\.modernButtonPreviewState, state)
    }
}

private struct TitlePaddingModifier: ViewModifier {
    var config: ButtonView.Config

    func body(content: Content) -> some View {
        switch config.size {
        case .small:
            content
                .padding(.top, 9)
                .padding(horizontalPaddingEdges, 16)
        case .medium:
            content
                .padding(.top, 13)
                .padding(horizontalPaddingEdges, 20)
        case .large:
            content
                .padding(.top, 18)
                .padding(horizontalPaddingEdges, 24)
        }
    }

    private var horizontalPaddingEdges: Edge.Set {
        guard let icon = config.icon else {
            return .horizontal
        }
        switch icon.alignment {
        case .leading:
            return .trailing
        case .trailing:
            return .leading
        }
    }
}

private struct IconPaddingModifier: ViewModifier {
    var config: ButtonView.Icon
    var size: ButtonView.Size

    func body(content: Content) -> some View {
        switch size {
        case .small:
            content
                .padding(.top, 10)
                .padding(horizontalPaddingEdges, 16)
        case .medium:
            content
                .padding(.top, 13)
                .padding(horizontalPaddingEdges, 20)
        case .large:
            content
                .padding(.top, 17)
                .padding(horizontalPaddingEdges, 24)
        }
    }

    private var horizontalPaddingEdges: Edge.Set {
        switch config.alignment {
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        }
    }
}

private extension View {
    func iconPadding(config: ButtonView.Icon, size: ButtonView.Size) -> some View {
        modifier(IconPaddingModifier(config: config, size: size))
    }

    func titlePadding(config: ButtonView.Config) -> some View {
        modifier(TitlePaddingModifier(config: config))
    }
}

private struct ButtonStateStyle: SwiftUI.ButtonStyle {
    let config: ButtonView.Config
    let cornerRadius: CGFloat
    let height: CGFloat

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.modernButtonPreviewState) private var previewStateOverride

    func makeBody(configuration: Configuration) -> some View {
        let state = state(isPressed: configuration.isPressed)

        VStack(spacing: 0) {
            configuration.label
                .foregroundStyle(Color(uiColor: config.textColor(for: state)))
            Spacer()
        }
        .frame(height: height)
        .background(
            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
            .fill(Color(uiColor: config.backgroundColor(for: state)))
        )
        .contentShape(
            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
        )
        .animation(.easeInOut(duration: 0.14), value: state)
    }

    private func state(isPressed: Bool) -> ButtonView.State {
        if let previewStateOverride {
            return previewStateOverride
        }

        if !isEnabled {
            return .disabled
        }

        if isPressed {
            return .highlighted
        }

        return .normal
    }
}

public struct ButtonView: View {
    public enum Size {
        case small
        case medium
        case large
    }

    public enum LayoutMode {
        case fill
        case intrinsic
    }

    public enum Appearance {
        case primary
        case secondary
        case secondaryOverlay
        case tertiary
        case overlay
        case destructive
    }

    public enum IconAlignment {
        case leading
        case trailing
    }

    public struct Icon {
        public var image: UIImage
        public var alignment: IconAlignment

        public init(
            image: UIImage,
            alignment: IconAlignment = .leading
        ) {
            self.image = image
            self.alignment = alignment
        }
    }

    public struct Config {
        public enum Title {
            case plain(String)
            case attributed(AttributedString)
        }

        public var title: Title
        public var size: Size
        public var appearance: Appearance
        public var layoutMode: LayoutMode
        public var icon: Icon?
        public var action: () -> Void

        public init(
            title: String,
            size: Size,
            layoutMode: LayoutMode = .intrinsic,
            appearance: Appearance,
            icon: Icon? = nil,
            action: @escaping () -> Void
        ) {
            self.title = .plain(title)
            self.size = size
            self.appearance = appearance
            self.layoutMode = layoutMode
            self.icon = icon
            self.action = action
        }

        public init(
            title: AttributedString,
            size: Size,
            layoutMode: LayoutMode = .intrinsic,
            appearance: Appearance,
            icon: Icon? = nil,
            action: @escaping () -> Void
        ) {
            self.title = .attributed(title)
            self.size = size
            self.appearance = appearance
            self.layoutMode = layoutMode
            self.icon = icon
            self.action = action
        }
    }

    enum State: Equatable {
        case normal
        case highlighted
        case disabled
    }

    public var config: Config

    public init(config: Config) {
        self.config = config
    }

    public var body: some View {
        SwiftUI.Button(action: config.action) {
            switch config.layoutMode {
            case .fill:
                content
                    .frame(maxWidth: .infinity)
            case .intrinsic:
                content
            }
        }
        .buttonStyle(
            ButtonStateStyle(
                config: config,
                cornerRadius: cornerRadius,
                height: height
            )
        )
    }

    private var content: some View {
        HStack(spacing: 8) {
            if let icon = config.icon {
                switch icon.alignment {
                case .leading:
                    iconView(icon)
                    titleView
                case .trailing:
                    titleView
                    iconView(icon)
                }
            } else {
                titleView
            }
        }
    }

    private func iconView(_ icon: Icon) -> some View {
        Image(uiImage: icon.image)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: iconSize, height: iconSize)
            .iconPadding(config: icon, size: config.size)
    }

    private var titleView: some View {
        Group {
            switch config.title {
            case let .plain(title):
                Text(title)
                    .textStyle(textStyle)
            case let .attributed(title):
                Text(title)
                    .textStyle(textStyle)
            }
        }
        .titlePadding(config: config)
    }

    private var iconSize: CGFloat {
        switch config.size {
        case .small, .medium, .large:
            16
        }
    }

    private var iconTrailingPadding: CGFloat {
        switch config.size {
        case .small, .medium, .large:
            8
        }
    }

    private var textStyle: TKTextStyle {
        switch config.size {
        case .large, .medium:
            .label1
        case .small:
            .label2
        }
    }

    private var cornerRadius: CGFloat {
        switch config.size {
        case .small:
            18
        case .medium:
            24
        case .large:
            16
        }
    }

    private var height: CGFloat {
        switch config.size {
        case .small:
            36
        case .medium:
            48
        case .large:
            56
        }
    }
}

private extension ButtonView.Config {
    func textColor(for state: ButtonView.State) -> UIColor {
        switch state {
        case .normal:
            normalTextColor
        case .highlighted:
            highlightedTextColor
        case .disabled:
            disabledTextColor
        }
    }

    func backgroundColor(for state: ButtonView.State) -> UIColor {
        switch state {
        case .normal:
            normalBackgroundColor
        case .highlighted:
            highlightedBackgroundColor
        case .disabled:
            disabledBackgroundColor
        }
    }

    private var normalTextColor: UIColor {
        switch appearance {
        case .primary:
            .Button.primaryForeground
        case .secondary, .secondaryOverlay:
            .Button.secondaryForeground
        case .tertiary:
            .Button.tertiaryForeground
        case .overlay:
            .Constant.black
        case .destructive:
            .Accent.red
        }
    }

    private var normalBackgroundColor: UIColor {
        switch appearance {
        case .primary:
            .Button.primaryBackground
        case .secondary:
            .Button.secondaryBackground
        case .secondaryOverlay:
            .clear
        case .tertiary:
            .Button.tertiaryBackground
        case .overlay:
            .Constant.white
        case .destructive:
            .Accent.red.withAlphaComponent(0.16)
        }
    }

    private var highlightedTextColor: UIColor {
        switch appearance {
        case .primary, .secondary, .secondaryOverlay, .tertiary, .overlay, .destructive:
            normalTextColor
        }
    }

    private var highlightedBackgroundColor: UIColor {
        switch appearance {
        case .primary:
            .Button.primaryBackgroundHighlighted
        case .secondary:
            .Button.secondaryBackgroundHighlighted
        case .secondaryOverlay:
            .clear
        case .tertiary:
            .Button.tertiaryBackgroundHighlighted
        case .overlay:
            .Button.overlayBackgroundHighlighted
        case .destructive:
            .Accent.red.withAlphaComponent(0.24)
        }
    }

    private var disabledTextColor: UIColor {
        switch appearance {
        case .primary, .secondary, .secondaryOverlay, .tertiary, .overlay, .destructive:
            normalTextColor.withAlphaComponent(0.48)
        }
    }

    private var disabledBackgroundColor: UIColor {
        switch appearance {
        case .primary:
            .Button.primaryBackgroundDisabled
        case .secondary:
            .Button.secondaryBackgroundDisabled
        case .secondaryOverlay:
            .clear
        case .tertiary:
            .Button.tertiaryBackgroundDisabled
        case .overlay:
            .Button.overlayBackgroundDisabled
        case .destructive:
            .Accent.red.withAlphaComponent(0.12)
        }
    }
}
