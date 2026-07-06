import SnapKit
import SwiftUI
import UIKit

public struct TKBottomSheetHeaderConfiguration {
    public enum IconPosition {
        case left
        case right
    }

    public enum ButtonContent {
        case icon(UIImage)
        case titleIcon(
            title: String? = nil,
            icon: UIImage? = nil,
            iconPosition: IconPosition = .left
        )
    }

    public struct Button {
        public enum Preset {
            case close
        }

        enum Kind {
            case custom(ButtonContent)
            case preset(Preset)
        }

        let kind: Kind
        public var action: ((_ button: UIControl) -> Void)?
        public var isEnabled: Bool

        public init(
            content: ButtonContent,
            action: @escaping ((_ button: UIControl) -> Void),
            isEnabled: Bool = true
        ) {
            kind = .custom(content)
            self.action = action
            self.isEnabled = isEnabled
        }

        private init(
            preset: Preset,
            action: ((_ button: UIControl) -> Void)?,
            isEnabled: Bool
        ) {
            kind = .preset(preset)
            self.action = action
            self.isEnabled = isEnabled
        }

        public static func close(
            action: ((_ button: UIControl) -> Void)? = nil,
            isEnabled: Bool = true
        ) -> Self {
            Self(
                preset: .close,
                action: action,
                isEnabled: isEnabled
            )
        }
    }

    public enum Title {
        public enum ContentLayout {
            case fitContent
            case fillWidth
        }

        public struct TextConfiguration {
            public let text: Text
            public let textStyle: TKTextStyle
            public let foregroundColor: UIColor?
            public let lineLimit: Int?
            public let truncationMode: Text.TruncationMode

            public init(
                text: Text,
                textStyle: TKTextStyle,
                foregroundColor: UIColor? = nil,
                lineLimit: Int? = 1,
                truncationMode: Text.TruncationMode = .tail
            ) {
                self.text = text
                self.textStyle = textStyle
                self.foregroundColor = foregroundColor
                self.lineLimit = lineLimit
                self.truncationMode = truncationMode
            }

            public init(
                _ string: String,
                textStyle: TKTextStyle,
                foregroundColor: UIColor? = nil,
                lineLimit: Int? = 1,
                truncationMode: Text.TruncationMode = .tail
            ) {
                self.init(
                    text: Text(string),
                    textStyle: textStyle,
                    foregroundColor: foregroundColor,
                    lineLimit: lineLimit,
                    truncationMode: truncationMode
                )
            }
        }

        case empty
        case title(
            title: String,
            subtitle: String? = nil,
            alignment: ModalCardHeaderContentAlignment = .center
        )
        case text(
            title: TextConfiguration,
            subtitle: TextConfiguration? = nil,
            alignment: ModalCardHeaderContentAlignment = .center
        )
        case customView(
            AnyView,
            alignment: ModalCardHeaderContentAlignment = .center,
            layout: ContentLayout = .fillWidth
        )

        public static func view<Content: View>(
            alignment: ModalCardHeaderContentAlignment = .center,
            layout: ContentLayout = .fillWidth,
            @ViewBuilder _ content: () -> Content
        ) -> Self {
            .customView(
                AnyView(content()),
                alignment: alignment,
                layout: layout
            )
        }

        public static func view(
            _ embeddedView: UIView,
            alignment: ModalCardHeaderContentAlignment = .center,
            layout: ContentLayout = .fillWidth
        ) -> Self {
            .view(
                alignment: alignment,
                layout: layout
            ) {
                TKBottomSheetUIKitTitleViewRepresentable(embeddedView: embeddedView)
            }
        }
    }

    let title: Title
    public let leftButton: Button?
    public let rightButton: Button?
    let contentInsets: UIEdgeInsets

    public init(
        title: Title,
        leftButton: Button? = nil,
        rightButton: Button? = .close(),
        contentInsets: UIEdgeInsets? = nil
    ) {
        let resolvedContentInsets: UIEdgeInsets
        if let contentInsets {
            resolvedContentInsets = contentInsets
        } else {
            let defaultContentInsets = UIEdgeInsets(
                top: 16,
                left: 16,
                bottom: 16,
                right: 16
            )
            let multilineContentInsets = UIEdgeInsets(
                top: 8,
                left: 16,
                bottom: 8,
                right: 16
            )
            switch title {
            case .empty, .customView:
                resolvedContentInsets = defaultContentInsets
            case let .title(_, subtitle, _):
                resolvedContentInsets = subtitle == nil
                    ? defaultContentInsets
                    : multilineContentInsets
            case let .text(_, subtitle, _):
                resolvedContentInsets = subtitle == nil
                    ? defaultContentInsets
                    : multilineContentInsets
            }
        }

        self.title = title
        self.leftButton = leftButton
        self.rightButton = rightButton
        self.contentInsets = resolvedContentInsets
    }
}

struct TKBottomSheetHeaderContentView: View {
    let configuration: TKBottomSheetHeaderConfiguration
    let closeAction: () -> Void

    var body: some View {
        ModalCardHeader(
            config: ModalCardHeader.Config(
                alignment: configuration.title.alignment
            )
        ) {
            buttonView(configuration.leftButton)
        } center: {
            titleView(configuration.title)
        } trailing: {
            buttonView(configuration.rightButton)
        }
        .padding(configuration.contentInsets.edgeInsets)
        .background(Color(uiColor: .Background.page))
    }
}

private extension TKBottomSheetHeaderContentView {
    @ViewBuilder
    func buttonView(_ button: TKBottomSheetHeaderConfiguration.Button?) -> some View {
        if let button {
            TKBottomSheetHeaderButtonRepresentable(
                button: button,
                closeAction: closeAction
            )
            .fixedSize(horizontal: true, vertical: true)
            .layoutPriority(1)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    func titleView(_ title: TKBottomSheetHeaderConfiguration.Title) -> some View {
        switch title {
        case .empty:
            EmptyView()
        case let .title(title, subtitle, alignment):
            textStack(
                title: .init(
                    title,
                    textStyle: .h3,
                    foregroundColor: .Text.primary
                ),
                subtitle: subtitle.map {
                    .init(
                        $0,
                        textStyle: .body2,
                        foregroundColor: .Text.secondary
                    )
                },
                alignment: alignment
            )
        case let .text(title, subtitle, alignment):
            textStack(
                title: title,
                subtitle: subtitle,
                alignment: alignment
            )
        case let .customView(view, alignment, layout):
            customView(
                view,
                alignment: alignment,
                layout: layout
            )
        }
    }

    @ViewBuilder
    func customView(
        _ view: AnyView,
        alignment: ModalCardHeaderContentAlignment,
        layout: TKBottomSheetHeaderConfiguration.Title.ContentLayout
    ) -> some View {
        switch layout {
        case .fitContent:
            view
                .fixedSize(horizontal: true, vertical: false)
                .frame(
                    minHeight: 32,
                    alignment: alignment.swiftUiAlignment
                )
        case .fillWidth:
            view
                .frame(
                    maxWidth: .infinity,
                    minHeight: 32,
                    alignment: alignment.swiftUiAlignment
                )
        }
    }

    func textStack(
        title: TKBottomSheetHeaderConfiguration.Title.TextConfiguration,
        subtitle: TKBottomSheetHeaderConfiguration.Title.TextConfiguration?,
        alignment: ModalCardHeaderContentAlignment
    ) -> some View {
        VStack(alignment: alignment.horizontalAlignment, spacing: 0) {
            configuredText(title)
            if let subtitle {
                configuredText(subtitle)
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 32,
            alignment: alignment.swiftUiAlignment
        )
    }

    @ViewBuilder
    func configuredText(
        _ configuration: TKBottomSheetHeaderConfiguration.Title.TextConfiguration
    ) -> some View {
        let text = configuration.text
            .textStyle(configuration.textStyle)
            .lineLimit(configuration.lineLimit)
            .truncationMode(configuration.truncationMode)

        if let foregroundColor = configuration.foregroundColor {
            text.foregroundStyle(Color(uiColor: foregroundColor))
        } else {
            text
        }
    }
}

private struct TKBottomSheetHeaderButtonRepresentable: UIViewRepresentable {
    let button: TKBottomSheetHeaderConfiguration.Button
    let closeAction: () -> Void

    func makeUIView(context: Context) -> TKBottomSheetHeaderButtonContainerView {
        let view = TKBottomSheetHeaderButtonContainerView()
        view.update(
            button: button,
            closeAction: closeAction
        )
        return view
    }

    func updateUIView(_ uiView: TKBottomSheetHeaderButtonContainerView, context: Context) {
        uiView.update(
            button: button,
            closeAction: closeAction
        )
    }
}

private final class TKBottomSheetHeaderButtonContainerView: UIView {
    private enum DisplayKind {
        case icon
        case titleIcon
    }

    private var displayKind: DisplayKind?
    private var embeddedButton: UIControl?

    func update(
        button: TKBottomSheetHeaderConfiguration.Button,
        closeAction: @escaping () -> Void
    ) {
        let desiredKind = displayKind(for: button)
        if desiredKind != displayKind {
            displayKind = desiredKind
            embeddedButton?.removeFromSuperview()
            embeddedButton = makeButton(for: desiredKind)
            if let embeddedButton {
                addSubview(embeddedButton)
                embeddedButton.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
        }

        guard let embeddedButton else { return }

        switch button.kind {
        case let .custom(content):
            configure(
                embeddedButton: embeddedButton,
                with: content
            )
        case let .preset(preset):
            configure(
                embeddedButton: embeddedButton,
                with: preset
            )
        }

        embeddedButton.isEnabled = button.isEnabled
        configureAction(
            for: embeddedButton,
            button: button,
            closeAction: closeAction
        )

        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        fittingSize
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        fittingSize
    }
}

private extension TKBottomSheetHeaderButtonContainerView {
    var fittingSize: CGSize {
        guard let embeddedButton else {
            return .zero
        }

        let size = embeddedButton.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize,
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )

        return CGSize(
            width: ceil(size.width),
            height: ceil(size.height)
        )
    }

    private func displayKind(
        for button: TKBottomSheetHeaderConfiguration.Button
    ) -> DisplayKind {
        switch button.kind {
        case let .custom(content):
            switch content {
            case .icon:
                return .icon
            case .titleIcon:
                return .titleIcon
            }
        case .preset:
            return .icon
        }
    }

    private func makeButton(for kind: DisplayKind) -> UIControl {
        switch kind {
        case .icon:
            return TKUIHeaderIconButton()
        case .titleIcon:
            return TKUIHeaderTitleIconButton()
        }
    }

    func configure(
        embeddedButton: UIControl,
        with content: TKBottomSheetHeaderConfiguration.ButtonContent
    ) {
        switch content {
        case let .icon(image):
            guard let button = embeddedButton as? TKUIHeaderIconButton else { return }
            button.configure(
                model: TKUIHeaderButtonIconContentView.Model(image: image)
            )
        case let .titleIcon(title, icon, iconPosition):
            guard let button = embeddedButton as? TKUIHeaderTitleIconButton else { return }
            let icon = icon.map {
                TKUIButtonTitleIconContentView.Model.Icon(
                    icon: $0,
                    position: iconPosition.tkUIKitPosition
                )
            }
            button.configure(
                model: TKUIButtonTitleIconContentView.Model(
                    title: title,
                    icon: icon
                )
            )
        }
    }

    func configure(
        embeddedButton: UIControl,
        with preset: TKBottomSheetHeaderConfiguration.Button.Preset
    ) {
        switch preset {
        case .close:
            configure(
                embeddedButton: embeddedButton,
                with: .icon(.TKUIKit.Icons.Size16.close)
            )
        }
    }

    func configureAction(
        for embeddedButton: UIControl,
        button: TKBottomSheetHeaderConfiguration.Button,
        closeAction: @escaping () -> Void
    ) {
        let action: (UIControl) -> Void = {
            switch button.kind {
            case let .custom(content):
                switch content {
                case .icon, .titleIcon:
                    return { control in
                        button.action?(control)
                    }
                }
            case let .preset(preset):
                switch preset {
                case .close:
                    return { control in
                        if let action = button.action {
                            action(control)
                        } else {
                            closeAction()
                        }
                    }
                }
            }
        }()

        if let embeddedButton = embeddedButton as? TKUIHeaderIconButton {
            embeddedButton.addTapAction {
                action(embeddedButton)
            }
        } else if let embeddedButton = embeddedButton as? TKUIHeaderTitleIconButton {
            embeddedButton.addTapAction {
                action(embeddedButton)
            }
        }
    }
}

private struct TKBottomSheetUIKitTitleViewRepresentable: UIViewRepresentable {
    let embeddedView: UIView

    func makeUIView(context: Context) -> TKBottomSheetUIKitTitleContainerView {
        let containerView = TKBottomSheetUIKitTitleContainerView()
        containerView.update(embeddedView: embeddedView)
        return containerView
    }

    func updateUIView(_ uiView: TKBottomSheetUIKitTitleContainerView, context: Context) {
        uiView.update(embeddedView: embeddedView)
    }
}

private final class TKBottomSheetUIKitTitleContainerView: UIView {
    private var embeddedView: UIView?

    func update(embeddedView: UIView) {
        if self.embeddedView !== embeddedView {
            self.embeddedView?.removeFromSuperview()
            self.embeddedView = embeddedView

            embeddedView.removeFromSuperview()
            addSubview(embeddedView)
            embeddedView.setContentHuggingPriority(.required, for: .horizontal)
            embeddedView.setContentHuggingPriority(.required, for: .vertical)
            embeddedView.setContentCompressionResistancePriority(.required, for: .horizontal)
            embeddedView.setContentCompressionResistancePriority(.required, for: .vertical)
            embeddedView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        embeddedView.setNeedsLayout()
        embeddedView.layoutIfNeeded()
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        fittingSize
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        fittingSize
    }
}

private extension TKBottomSheetUIKitTitleContainerView {
    var fittingSize: CGSize {
        guard let embeddedView else {
            return .zero
        }

        embeddedView.setNeedsLayout()
        embeddedView.layoutIfNeeded()

        let size = embeddedView.systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize,
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )

        return CGSize(
            width: ceil(size.width),
            height: ceil(size.height)
        )
    }
}

private extension TKBottomSheetHeaderConfiguration.Title {
    var alignment: ModalCardHeaderContentAlignment {
        switch self {
        case .empty:
            return .center
        case let .title(_, _, alignment):
            return alignment
        case let .text(_, _, alignment):
            return alignment
        case let .customView(_, alignment, _):
            return alignment
        }
    }
}

private extension TKBottomSheetHeaderConfiguration.IconPosition {
    var tkUIKitPosition: TKUIButtonTitleIconContentView.Model.IconPosition {
        switch self {
        case .left:
            return .left
        case .right:
            return .right
        }
    }
}

private extension ModalCardHeaderContentAlignment {
    var horizontalAlignment: HorizontalAlignment {
        switch self {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
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
