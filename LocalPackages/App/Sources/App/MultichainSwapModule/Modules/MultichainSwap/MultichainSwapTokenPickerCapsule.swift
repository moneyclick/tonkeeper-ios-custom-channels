import SwiftUI
import TKUIKit

struct MultichainSwapTokenPickerCapsule: View {
    let imageSource: AssetAvatarViewImageSource
    let symbol: String
    let network: String?
    let action: () -> Void

    init(
        imageSource: AssetAvatarViewImageSource,
        symbol: String,
        network: String? = nil,
        action: @escaping () -> Void
    ) {
        self.imageSource = imageSource
        self.symbol = symbol
        self.network = network
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                AssetAvatarView(imageSource: imageSource, size: .extraSmall)
                HStack(spacing: 0) {
                    Text(symbol)
                        .textStyle(.label2)
                        .foregroundColor(Color(uiColor: .Text.primary))
                    if let network {
                        Text(" " + network)
                            .textStyle(.label2)
                            .foregroundColor(Color(uiColor: .Text.secondary))
                    }
                }
                SwiftUI.Image(uiImage: UIImage.TKUIKit.Icons.Size16.switch)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color(uiColor: .Icon.secondary))
            }
            .padding(.leading, 8)
            .padding(.trailing, 12)
            .padding(.vertical, 8)
            .background(Color(uiColor: .Background.contentTint))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
