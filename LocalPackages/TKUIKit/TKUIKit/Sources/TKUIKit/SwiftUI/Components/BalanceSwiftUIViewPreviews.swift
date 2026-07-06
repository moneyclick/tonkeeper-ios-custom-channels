import SwiftUI

public struct BalanceSwiftUIViewPreviews: View {
    @State private var hasLoadingStatus = false
    @State private var hasStatus = true
    @State private var hasAddress = true
    @State private var shimmering = false
    @State private var longAddress = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                BalanceSwiftUIView(config: shimmering ? .shimmer : .content(content))
                    .animation(.default, value: content)
                    .animation(.default, value: shimmering)

                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: $hasLoadingStatus) {
                        toggleTitle("Loading status")
                    }

                    Toggle(isOn: $hasStatus) {
                        toggleTitle("Status")
                    }

                    Toggle(isOn: $hasAddress) {
                        toggleTitle("Address")
                    }

                    Toggle(isOn: $shimmering) {
                        toggleTitle("Shimmer")
                    }

                    Toggle(isOn: $longAddress) {
                        toggleTitle("Long address")
                    }
                    .disabled(!hasAddress)
                    .opacity(hasAddress ? 1 : 0.48)
                }
            }
            .padding(.all, 16)
        }
        .debugPreview(
            backgroundColor: Color(uiColor: .Background.page)
        )
    }
}

private extension BalanceSwiftUIViewPreviews {
    var content: BalanceViewContent {
        BalanceViewContent(
            balance: BalanceViewContent.Balance(
                leadingText: "$",
                text: "7 362"
            ),
            address: statusConfig,
            battery: BatterySwiftUIViewConfig(
                size: .size34,
                state: .fill(0.5)
            )
        )
    }

    var statusConfig: BalanceHeaderBalanceStatusViewConfig? {
        if hasLoadingStatus {
            return BalanceHeaderBalanceStatusViewConfig(
                state: .connection(BalanceHeaderBalanceStatusViewConfig.ConnectionStatus(
                    title: "Updating",
                    titleColor: .Text.secondary,
                    isLoading: true
                ))
            )
        }

        if hasStatus {
            return BalanceHeaderBalanceStatusViewConfig(
                state: .updated("Updated at 12:48")
            )
        }

        if hasAddress {
            return BalanceHeaderBalanceStatusViewConfig(
                state: .address(
                    "Your address: \(address)",
                    tags: [
                        .tag(text: "v4r2"),
                        .accentTag(text: "w5", color: .Accent.blue),
                    ]
                )
            )
        }

        return nil
    }

    var address: String {
        longAddress
            ? "UQDxzbcLzjNqQp5sGzj4wEGMMeEuP6eqxEGEcPlBrsf92"
            : "UQDx...sf92"
    }

    func toggleTitle(_ title: String) -> some View {
        Text(title)
            .textStyle(.body2)
            .foregroundStyle(Color(uiColor: .Text.primary))
    }
}

#Preview {
    BalanceSwiftUIViewPreviews()
}
