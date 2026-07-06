import SwiftUI

public struct WalletButtonPreviews: View {
    public init() {}

    let configs: [WalletButtonConfig] = [
        WalletButtonConfig(
            title: "Main Wallet",
            icon: .emoji("💎"),
            color: .Background.content
        ),
        WalletButtonConfig(
            title: "Money",
            icon: .image(.TKUIKit.Icons.Size16.wallet),
            color: UIColor(hex: "69CC5A")
        ),
        WalletButtonConfig(
            title: "Very Long Wallet Name",
            icon: .emoji("🐉"),
            color: UIColor(hex: "925CFF")
        ),
    ]

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(configs, id: \.self) { config in
                WalletButton(config: config, action: {})
                    .frame(maxWidth: 220, alignment: .leading)
            }
        }
        .padding(.all, 16)
        .debugPreview(
            backgroundColor: Color(uiColor: .Background.page)
        )
    }
}

#Preview {
    WalletButtonPreviews()
}
