import Kingfisher
import SwiftUI
import UIKit

struct BannerItemModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                    .strokeBorder(Color(uiColor: .Button.tertiaryBackground), lineWidth: Layout.borderWidth)
            )
            .contentShape(Rectangle())
    }

    enum Layout {
        static let cornerRadius: CGFloat = 20
        static let borderWidth: CGFloat = 1
    }
}

extension View {
    func bannerItem() -> some View {
        modifier(BannerItemModifier())
    }
}

struct BannerItemView: View {
    let item: BannerItem
    let onTapDismiss: () -> Void
    let height: CGFloat

    init(item: BannerItem, height: CGFloat, onTapDismiss: @escaping () -> Void = {}) {
        self.item = item
        self.height = height
        self.onTapDismiss = onTapDismiss
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(item.title)
                        .textStyle(.label2)
                        .foregroundStyle(Color(uiColor: .Text.primary))
                        .lineLimit(2)
                        .padding(.top, Layout.titleTopPadding)
                        .padding(.leading, Layout.titleLeadingPadding)
                    HStack(alignment: .top, spacing: 0) {
                        actionView
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                bannerImage(width: geometry.size.width * Layout.imageWidthRatio)
            }
            .frame(width: geometry.size.width, height: height, alignment: .top)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: bannerBackgroundColor))
        .overlay {
            HStack {
                Spacer()
                VStack {
                    closeButton
                    Spacer()
                }
            }
        }
    }

    private var closeButton: some View {
        Button {
            onTapDismiss()
        } label: {
            Image(uiImage: .TKUIKit.Icons.Size16.closeSmall)
                .renderingMode(.template)
                .resizable()
                .frame(
                    width: Layout.closeIconSize,
                    height: Layout.closeIconSize
                )
                .foregroundStyle(Color(uiColor: .Icon.secondary))
                .padding(Layout.closeIconPadding)
                .background(Color(uiColor: closeButtonBackgroundColor))
                .clipShape(Circle())
        }
        .padding(Layout.closeButtonPadding)
        .accessibilityIdentifier("home_banner_close")
    }

    @ViewBuilder
    private func bannerImage(width: CGFloat) -> some View {
        if let imageURL = item.imageURL {
            BannerRemoteImageView(url: imageURL, width: width, height: height)
        } else {
            defaultBannerImage(width: width)
        }
    }

    @ViewBuilder
    private var actionView: some View {
        if let action = item.action {
            Button(action: action) {
                actionLabel
            }
            .buttonStyle(BannerOpacityButtonStyle())
        } else {
            actionLabel
        }
    }

    private var actionLabel: some View {
        actionLabelText
            .textStyle(.body3)
            .padding(.top, Layout.subtitleTopPadding)
            .padding(.leading, Layout.subtitleLeadingPadding)
            .contentShape(Rectangle())
    }

    private var actionLabelText: Text {
        Text(descriptionText)
            .foregroundColor(Color(uiColor: .Text.primary.withAlphaComponent(0.64)))
            + Text("\u{00A0}")
            .kerning(Layout.subtitleAccessoryLeadingAdjustment)
            + Text(Image(uiImage: .TKUIKit.Icons.Size12.chevronRight.withRenderingMode(.alwaysTemplate)))
            .baselineOffset(Layout.subtitleAccessoryBaselineOffset)
            .foregroundColor(Color(uiColor: .Text.primary.withAlphaComponent(0.64)))
    }

    private var descriptionText: String {
        item.description.isEmpty ? item.actionTitle : item.description
    }

    private var bannerBackgroundColor: UIColor {
        UIColor {
            let scheme = TKThemeManager.shared.themeAppearance.colorScheme(for: $0.userInterfaceStyle)
            if scheme is LightColorScheme {
                return scheme.backgroundPageAlternate
            }
            return scheme.backgroundPage
        }
    }

    private var closeButtonBackgroundColor: UIColor {
        UIColor {
            let scheme = TKThemeManager.shared.themeAppearance.colorScheme(for: $0.userInterfaceStyle)
            if scheme is LightColorScheme {
                return scheme.backgroundContentAlternate
            }
            return scheme.backgroundContent
        }
    }

    private func defaultBannerImage(width: CGFloat) -> some View {
        Image(uiImage: .TKUIKit.Icons.Vector.multichainBanner)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .clipped()
    }
}

extension BannerItemView {
    enum Layout {
        static let imageWidthRatio: CGFloat = 1.0 / 3.0
        static let titleTopPadding: CGFloat = 16
        static let titleLeadingPadding: CGFloat = 16
        static let subtitleTopPadding: CGFloat = 6
        static let subtitleLeadingPadding: CGFloat = 16
        static let subtitleAccessoryLeadingAdjustment: CGFloat = -1
        static let subtitleAccessoryBaselineOffset: CGFloat = -2
        static let closeIconSize: CGFloat = 16
        static let closeIconPadding: CGFloat = 4
        static let closeButtonPadding: CGFloat = 10
    }
}

private struct BannerOpacityButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
    }
}

private struct BannerRemoteImageView: View {
    let url: URL
    let width: CGFloat
    let height: CGFloat

    @State private var didFail = false

    var body: some View {
        Group {
            if didFail {
                fallbackImage
            } else {
                KFImage
                    .url(url)
                    .setProcessor(
                        DownsamplingImageProcessor(
                            size: CGSize(
                                width: max(width, 1) * UIScreen.main.scale,
                                height: max(height, 1) * UIScreen.main.scale
                            )
                        )
                    )
                    .loadDiskFileSynchronously()
                    .fade(duration: 0)
                    .placeholder {
                        ShimmerSwiftUIView(config: shimmerConfig)
                            .frame(width: width, height: height)
                    }
                    .onSuccess { _ in
                        didFail = false
                    }
                    .onFailure { _ in
                        didFail = true
                    }
                    .cancelOnDisappear(true)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            }
        }
        .id(url)
    }

    private var fallbackImage: some View {
        Image(uiImage: .TKUIKit.Icons.Vector.multichainBanner)
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .clipped()
    }

    private var shimmerConfig: ShimmerSwiftUIView.Config {
        ShimmerSwiftUIView.Config(color: .Background.contentTint)
    }
}
