import SwiftUI

public struct TKTagSwiftUIViewPreviews: View {
    public init() {}

    private let configs: [TKTagSwiftUIViewConfig] = [
        .tag(text: "v4r2"),
        .accentTag(text: "w5", color: .Accent.blue),
        .accentTag(text: "beta", color: .Accent.green),
        .outlineTag(text: "watch"),
    ]

    public var body: some View {
        HStack(spacing: 12) {
            ForEach(configs, id: \.self) { config in
                TKTagSwiftUIView(config: config)
                    .border(.cyan)
            }
        }
        .padding(.all, 16)
        .debugPreview()
    }
}

#Preview {
    TKTagSwiftUIViewPreviews()
}
