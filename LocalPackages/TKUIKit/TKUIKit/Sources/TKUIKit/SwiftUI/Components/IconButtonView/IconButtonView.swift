import SwiftUI

public enum IconButtonViewConfig: Hashable {
    case content(IconButtonViewContent)
    case shimmer(hasTitle: Bool)
}

public struct IconButtonViewContent: Hashable {
    public var icon: UIImage
    public var title: String?

    public init(
        icon: UIImage,
        title: String? = nil
    ) {
        self.icon = icon
        self.title = title
    }
}

public struct IconButtonView: View {
    var config: IconButtonViewConfig

    public init(config: IconButtonViewConfig) {
        self.config = config
    }

    public var body: some View {
        VStack(spacing: 0) {
            iconView
                .clipShape(Circle())
                .padding(Layout.iconContainerInsets)
            titleView
        }
    }

    @ViewBuilder
    private var iconView: some View {
        switch config {
        case let .content(content):
            Image(uiImage: content.icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color(uiColor: .Button.tertiaryForeground))
                .frame(
                    width: Layout.iconSize,
                    height: Layout.iconSize
                )
                .padding(Layout.iconInsets)
                .background(Color(uiColor: .Button.tertiaryBackground))
        case .shimmer:
            ShimmerSwiftUIView()
                .frame(
                    width: [
                        Layout.iconInsets.leading,
                        Layout.iconSize,
                        Layout.iconInsets.trailing,
                    ].reduce(0, +),
                    height: [
                        Layout.iconInsets.top,
                        Layout.iconSize,
                        Layout.iconInsets.bottom,
                    ].reduce(0, +)
                )
        }
    }

    @ViewBuilder
    private var titleView: some View {
        switch config {
        case let .content(content):
            if let title = content.title {
                Text(title)
                    .textStyle(Layout.titleTextStyle)
                    .foregroundStyle(Color(uiColor: .Text.secondary))
                    .frame(maxWidth: Layout.width, alignment: .center)
                    .padding(.bottom, Layout.titleBottomPadding)
                    .padding(.bottom, Layout.titleContainerBottomPadding)
            } else {
                EmptyView()
            }
        case let .shimmer(hasTitle):
            if hasTitle {
                ShimmerSwiftUIView(
                    config: ShimmerSwiftUIView.Config(
                        cornerRadius: .capsule
                    )
                )
                .frame(width: 60, height: Layout.titleTextStyle.lineHeight)
                .padding(.bottom, Layout.titleContainerBottomPadding)
            } else {
                EmptyView()
            }
        }
    }
}

extension IconButtonView {
    enum Layout {
        static let iconSize: CGFloat = 28
        static let iconInsets = EdgeInsets(
            top: 8,
            leading: 8,
            bottom: 8,
            trailing: 8
        )
        static let iconContainerInsets = EdgeInsets(
            top: 8,
            leading: 16,
            bottom: 8,
            trailing: 16
        )
        static let titleTextStyle: TKTextStyle = .label3
        static let titleBottomPadding: CGFloat = 2
        static let titleContainerBottomPadding: CGFloat = 8

        static var width: CGFloat {
            [
                iconContainerInsets.leading,
                iconInsets.leading,
                iconSize,
                iconInsets.trailing,
                iconContainerInsets.trailing,
            ].reduce(0, +)
        }
    }
}
