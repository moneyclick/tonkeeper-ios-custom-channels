import SwiftUI

public struct InfoRowView: View {
    public struct Hover {
        var onTap: () -> Void

        public init(onTap: @escaping () -> Void) {
            self.onTap = onTap
        }
    }

    public struct Delta {
        var text: String
        var isPositive: Bool

        public init(text: String, isPositive: Bool) {
            self.text = text
            self.isPositive = isPositive
        }
    }

    let title: String
    let valueText: String
    let delta: Delta?
    let hintText: String?

    public init(
        title: String,
        valueText: String,
        delta: Delta?,
        hintText: String?
    ) {
        self.title = title
        self.valueText = valueText
        self.delta = delta
        self.hintText = hintText
    }

    public var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                Text(title)
                    .textStyle(.body1)
                    .foregroundStyle(Color(uiColor: .Text.secondary))
                    .padding(.top, Layout.titleTopPadding)
                Spacer()
            }

            if let hintText {
                VStack(spacing: 0) {
                    HintButton(
                        configuration: HintConfiguration(
                            position: HintPosition(
                                tailParameters: TKHintTextView.tailParameters,
                                horizontal: .default,
                                vertical: .init(absolute: 1),
                                direction: .bottomLeft
                            ),
                            maximumWidth: Layout.hintMaximumWidth,
                            animationStyle: .bouncing
                        )
                    ) { position in
                        TKHintTextView(
                            text: hintText,
                            position: position
                        )
                    } label: {
                        hintIcon
                    }
                    Spacer()
                }
                .padding(.top, Layout.hoverTopPadding)
                .padding(.leading, Layout.hoverLeadingPadding)
            }

            Spacer(minLength: Layout.minimumSpacer)

            HStack(spacing: Layout.deltaSpacing) {
                Text(valueText)
                    .textStyle(.label1)
                    .foregroundStyle(Color(uiColor: .Text.primary))

                if let delta {
                    Text(delta.text)
                        .textStyle(.body1)
                        .foregroundStyle(
                            Color(uiColor: delta.isPositive ? .Accent.green : .Accent.red)
                        )
                }
            }
            .padding(.top, Layout.valueTopPadding)
        }
        .frame(height: Layout.height)
    }

    private var hintIcon: some View {
        SwiftUI.Image(uiImage: .TKUIKit.Icons.Size16.informationCircle)
            .renderingMode(.template)
            .foregroundStyle(Color(uiColor: .Text.secondary))
            .frame(width: Layout.hintIconSize, height: Layout.hintIconSize)
    }
}

private extension InfoRowView {
    enum Layout {
        static let titleTopPadding: CGFloat = 19
        static let hoverTopPadding: CGFloat = 20
        static let hoverLeadingPadding: CGFloat = 4
        static let minimumSpacer: CGFloat = 10
        static let deltaSpacing: CGFloat = 4
        static let valueTopPadding: CGFloat = 2
        static let height: CGFloat = 56
        static let hintMaximumWidth: CGFloat = 200
        static let hintIconSize: CGFloat = 16
    }
}

#Preview {
    VStack(spacing: 0) {
        InfoRowView(
            title: "Market Cap",
            valueText: "$ 3.65B",
            delta: InfoRowView.Delta(
                text: "+2.24 %",
                isPositive: true
            ),
            hintText: "test hint"
        )
        InfoRowView(
            title: "Market Cap",
            valueText: "$ 3.65B",
            delta: nil,
            hintText: "test hint\ntest hint"
        )
        InfoRowView(
            title: "Market Cap",
            valueText: "$ 3.65B",
            delta: nil,
            hintText: nil
        )
    }
    .padding(.horizontal, 12)
    .debugPreview(
        backgroundColor: Color(uiColor: .Background.page)
    )
}
