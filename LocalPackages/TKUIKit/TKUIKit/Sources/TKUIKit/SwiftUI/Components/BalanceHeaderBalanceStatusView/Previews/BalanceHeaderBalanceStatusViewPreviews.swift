import SwiftUI

public struct BalanceHeaderBalanceStatusViewPreviews: View {
    public init() {}

    private let configs: [PreviewConfig] = [
        PreviewConfig(
            title: "Address",
            config: BalanceHeaderBalanceStatusViewConfig(
                state: .address("UQDx...sf92", tags: [])
            )
        ),
        PreviewConfig(
            title: "Address with tags",
            config: BalanceHeaderBalanceStatusViewConfig(
                state: .address(
                    "UQDx...sf92",
                    tags: [
                        .tag(text: "v4r2"),
                        .accentTag(text: "w5", color: .Accent.blue),
                    ]
                )
            )
        ),
        PreviewConfig(
            title: "Long address",
            config: BalanceHeaderBalanceStatusViewConfig(
                state: .address(
                    "UQDxzbcLzjNqQp5sGzj4wEGMMeEuP6eqxEGEcPlBrsf92",
                    tags: [
                        .outlintTag(text: "watch"),
                    ]
                )
            )
        ),
        PreviewConfig(
            title: "Updated",
            config: BalanceHeaderBalanceStatusViewConfig(
                state: .updated("Updated at 12:48")
            )
        ),
        PreviewConfig(
            title: "Updating",
            config: BalanceHeaderBalanceStatusViewConfig(
                state: .connection(BalanceHeaderBalanceStatusViewConfig.ConnectionStatus(
                    title: "Updating",
                    titleColor: .Text.secondary,
                    isLoading: true
                ))
            )
        ),
        PreviewConfig(
            title: "No internet",
            config: BalanceHeaderBalanceStatusViewConfig(
                state: .connection(BalanceHeaderBalanceStatusViewConfig.ConnectionStatus(
                    title: "No internet connection",
                    titleColor: .Accent.orange,
                    isLoading: false
                ))
            )
        ),
    ]

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(configs, id: \.self) { previewConfig in
                VStack(alignment: .leading, spacing: 8) {
                    Text(previewConfig.title)
                        .textStyle(.label1)
                        .foregroundStyle(Color(uiColor: .Text.primary))

                    BalanceHeaderBalanceStatusView(config: previewConfig.config)
                }
            }
        }
        .padding(.all, 16)
        .debugPreview()
    }
}

private extension BalanceHeaderBalanceStatusViewPreviews {
    struct PreviewConfig: Hashable {
        let title: String
        let config: BalanceHeaderBalanceStatusViewConfig
    }
}

#Preview {
    BalanceHeaderBalanceStatusViewPreviews()
}
