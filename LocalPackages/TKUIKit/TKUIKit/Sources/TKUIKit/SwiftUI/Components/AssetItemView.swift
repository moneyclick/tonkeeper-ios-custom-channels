import SwiftUI
import UIKit

public enum AssetItemViewContent {
    case shimmer
    case content(
        symbol: String,
        imageSource: AssetAvatarViewImageSource,
        changeText: String?,
        changeColor: Color
    )
}

public struct AssetItemView: View {
    let content: AssetItemViewContent
    private let action: () -> Void

    public init(
        symbol: String,
        imageSource: AssetAvatarViewImageSource,
        changeText: String?,
        changeColor: Color,
        action: @escaping () -> Void
    ) {
        self.init(
            content: .content(
                symbol: symbol,
                imageSource: imageSource,
                changeText: changeText,
                changeColor: changeColor
            ),
            action: action
        )
    }

    public init(
        content: AssetItemViewContent,
        action: @escaping () -> Void
    ) {
        self.content = content
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack {
                VStack(spacing: Layout.contentSpacing) {
                    avatarView
                    captionView
                }
                .padding(.top, Layout.verticalPadding)
                Spacer()
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .frame(height: Layout.height)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(AssetItemHighlightButtonStyle())
    }

    @ViewBuilder
    private var captionView: some View {
        switch content {
        case .shimmer:
            VStack(spacing: 4) {
                ShimmerSwiftUIView(
                    config: ShimmerSwiftUIView.Config(
                        color: .Background.contentTint,
                        cornerRadius: .capsule
                    )
                )
                .frame(width: 59, height: 12)
                .padding(.top, 2)
                ShimmerSwiftUIView(
                    config: ShimmerSwiftUIView.Config(
                        color: .Background.contentTint,
                        cornerRadius: .capsule
                    )
                )
                .frame(width: 35, height: 12)
            }
        case let .content(symbol, _, changeText, changeColor):
            VStack(spacing: Layout.captionSpacing) {
                Text(symbol)
                    .textStyle(.body3)
                    .foregroundStyle(Color(uiColor: .Text.primary))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)

                if let changeText {
                    Text(changeText)
                        .textStyle(.body3)
                        .foregroundStyle(changeColor)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var avatarView: some View {
        switch content {
        case .shimmer:
            AssetAvatarView(
                imageSource: .shimmer,
                size: .regular
            )
        case let .content(_, imageSource, _, _):
            AssetAvatarView(
                imageSource: imageSource,
                size: .regular
            )
        }
    }
}

private extension AssetItemView {
    enum Layout {
        static let captionSpacing: CGFloat = 1
        static let contentSpacing: CGFloat = 8
        static let horizontalPadding: CGFloat = 2
        static let height: CGFloat = 113
        static let shimmerCaptionCornerRadius: CGFloat = 8
        static let shimmerCaptionHeight: CGFloat = 16
        static let shimmerCaptionWidth: CGFloat = 40
        static let verticalPadding: CGFloat = 8
    }
}

private struct AssetItemHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
    }
}

#Preview {
    HStack(spacing: 0) {
        Spacer()
        AssetItemView(
            symbol: "TON",
            imageSource: .image(nil, chainIcon: nil),
            changeText: "+ 1.23 %",
            changeColor: Color(uiColor: .Accent.green),
            action: {}
        )
        .border(.cyan)
//        Spacer()
        AssetItemView(
            content: .shimmer,
            action: {}
        )
        .border(.cyan)
        Spacer()
    }
    .debugPreview()
}
