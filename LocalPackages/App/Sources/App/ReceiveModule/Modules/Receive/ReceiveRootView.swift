import SwiftUI
import TKLocalize
import TKUIKit

struct ReceiveRootView: View {
    @ObservedObject var viewModel: ReceiveViewModelImplementation

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear

            VStack(spacing: 0) {
                ReceiveTitleBlockView(network: viewModel.selectedNetwork)

                ReceiveQRCardView(
                    image: viewModel.qrCodeImage,
                    network: viewModel.selectedNetwork,
                    onCopy: viewModel.copyAddress
                )
                .padding(.top, Layout.cardTopPadding)
                .padding(.horizontal, Layout.cardHorizontalPadding)

                ReceiveActionRowView(
                    onCopy: viewModel.copyAddress,
                    onShare: viewModel.shareSelectedAddress
                )
                .padding(.top, Layout.actionsTopPadding)
                .padding(.bottom, Layout.actionsBottomPadding)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color.clear)
    }
}

private extension ReceiveRootView {
    enum Layout {
        static let actionsBottomPadding: CGFloat = 16
        static let actionsTopPadding: CGFloat = 16
        static let cardHorizontalPadding: CGFloat = 47
        static let cardTopPadding: CGFloat = 32
        static let titleHorizontalPadding: CGFloat = 32
    }
}

struct ReceiveTitleBlockView: View {
    let network: ReceiveNetworkViewData

    var body: some View {
        VStack(spacing: 4) {
            Text(network.addressTitle)
                .textStyle(.h3)
                .foregroundStyle(Color(uiColor: .Text.primary))

            Text(network.disclaimer)
                .textStyle(.body1)
                .foregroundStyle(Color(uiColor: .Text.secondary))
                .multilineTextAlignment(.center)
                .padding(.top, 3)
        }
        .padding(.horizontal, ReceiveRootView.Layout.titleHorizontalPadding)
    }
}

struct ReceiveQRCardView: View {
    let image: UIImage?
    let network: ReceiveNetworkViewData
    let onCopy: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ReceiveQRCodeImageView(
                image: image,
                network: network
            )
            .padding(.horizontal, 24)

            Button(action: onCopy) {
                Text(network.address.multilineReceiveAddress)
                    .textStyle(.body1Mono)
                    .foregroundStyle(Color.black)
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 28)
            }
        }
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
    }
}

struct ReceiveActionRowView: View {
    let onCopy: () -> Void
    let onShare: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ReceiveActionButton(
                title: TKLocales.Actions.copy,
                icon: .TKUIKit.Icons.Size16.copy,
                style: .compact,
                action: onCopy
            )

            ReceiveActionButton(
                title: nil,
                icon: .TKUIKit.Icons.Size16.share,
                style: .icon,
                action: onShare
            )
        }
    }
}

private struct ReceiveQRCodeImageView: View {
    let image: UIImage?
    let network: ReceiveNetworkViewData

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white)

            if let image {
                SwiftUI.Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else {
                ProgressView()
                    .tint(Color.black)
            }

            AssetAvatarView(
                imageSource: .image(network.icon),
                configuration: Layout.avatarConfiguration
            )
            .padding(8)
            .background(Color.white)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct ReceiveActionButton: View {
    enum Style {
        case compact
        case icon
    }

    let title: String?
    let icon: UIImage
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                SwiftUI.Image(uiImage: icon)
                    .renderingMode(.template)

                if let title {
                    Text(title)
                        .textStyle(.label1)
                }
            }
            .foregroundStyle(Color(uiColor: .Button.secondaryForeground))
            .frame(height: 48)
            .padding(.horizontal, horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(uiColor: .Button.secondaryBackground))
            )
        }
        .buttonStyle(.plain)
    }

    private var horizontalPadding: CGFloat {
        switch style {
        case .compact:
            20
        case .icon:
            16
        }
    }
}

private extension String {
    var multilineReceiveAddress: String {
        let characters = Array(self)
        guard characters.count > 16 else {
            return self
        }

        let midpoint = Int(ceil(Double(characters.count) / 2.0))
        return String(characters[..<midpoint]) + "\n" + String(characters[midpoint...])
    }
}

private extension ReceiveQRCodeImageView {
    enum Layout {
        static let avatarConfiguration = AssetAvatarView.Configuration(
            imageSize: 40,
            chainIconSize: 16,
            chainIconPadding: 2,
            chainIconOffsetX: 4,
            chainIconOffsetY: 4
        )
    }
}
