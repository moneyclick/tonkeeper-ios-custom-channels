import SwiftUI

public struct TKHintTextView: View {
    enum Layout {
        static let cornerRadius: CGFloat = 12
        static let tailCornerRadius: CGFloat = 3
        static let tailSize = CGSize(width: 12, height: 6)
        static let tailOffset: CGFloat = 24
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 9
        static let bottomPadding: CGFloat = 11
        static let shadowOpacity: CGFloat = 0.04
        static let shadowRadius: CGFloat = 8
        static let shadowYOffset: CGFloat = 4
    }

    private let text: String
    private let position: HintPosition.Direction?

    public init(
        text: String,
        position: HintPosition.Direction? = nil
    ) {
        self.text = text
        self.position = position
    }

    public var body: some View {
        Text(text)
            .textStyle(.body2)
            .foregroundStyle(Color(uiColor: .Text.primary))
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.top, Layout.topPadding)
            .padding(.bottom, Layout.bottomPadding)
            .withTail(
                appearance: Self.appearance,
                parameters: Self.tailParameters,
                direction: position
            )
    }
}

extension TKHintTextView: HintView {
    public static var tailParameters: HintTailParameters? {
        HintTailParameters(
            horizontalOffset: Layout.tailOffset,
            size: Layout.tailSize,
            tailCornerRadius: Layout.tailCornerRadius
        )
    }
}

#Preview {
    VStack(spacing: 48) {
        ZStack(alignment: .bottomTrailing) {
            TKHintTextView(
                text: "Top Left",
                position: .topLeft
            )
            .border(.red)

            VStack(
                alignment: .trailing,
                spacing: TKHintTextView.Layout.tailSize.height - 2
            ) {
                Rectangle()
                    .frame(width: TKHintTextView.Layout.tailSize.width, height: 1)
                    .foregroundStyle(.green)
                    .padding(.trailing, TKHintTextView.Layout.tailOffset - TKHintTextView.Layout.tailSize.width / 2)
                Rectangle()
                    .frame(width: TKHintTextView.Layout.tailOffset, height: 1)
                    .foregroundStyle(.cyan)
            }
        }

        ZStack(alignment: .bottomLeading) {
            TKHintTextView(
                text: "Top Right",
                position: .topRight
            )
            .border(.red)
            VStack(
                alignment: .leading,
                spacing: TKHintTextView.Layout.tailSize.height - 2
            ) {
                Rectangle()
                    .frame(width: TKHintTextView.Layout.tailSize.width, height: 1)
                    .foregroundStyle(.green)
                    .padding(.leading, TKHintTextView.Layout.tailOffset - TKHintTextView.Layout.tailSize.width / 2)
                Rectangle()
                    .frame(width: TKHintTextView.Layout.tailOffset, height: 1)
                    .foregroundStyle(.cyan)
            }
        }

        TKHintTextView(
            text: "No Tail",
            position: nil
        )
        .border(.red)

        ZStack(alignment: .topTrailing) {
            TKHintTextView(
                text: "Bottom Left",
                position: .bottomLeft
            )
            .border(.red)
            VStack(
                alignment: .trailing,
                spacing: TKHintTextView.Layout.tailSize.height - 2
            ) {
                Rectangle()
                    .frame(width: TKHintTextView.Layout.tailOffset, height: 1)
                    .foregroundStyle(.cyan)
                Rectangle()
                    .frame(width: TKHintTextView.Layout.tailSize.width, height: 1)
                    .foregroundStyle(.green)
                    .padding(.trailing, TKHintTextView.Layout.tailOffset - TKHintTextView.Layout.tailSize.width / 2)
            }
        }

        ZStack(alignment: .topLeading) {
            TKHintTextView(
                text: "Bottom Right",
                position: .bottomRight
            )
            .border(.red)
            VStack(
                alignment: .leading,
                spacing: TKHintTextView.Layout.tailSize.height - 2
            ) {
                Rectangle()
                    .frame(width: TKHintTextView.Layout.tailOffset, height: 1)
                    .foregroundStyle(.cyan)
                Rectangle()
                    .frame(width: TKHintTextView.Layout.tailSize.width, height: 1)
                    .foregroundStyle(.green)
                    .padding(.leading, TKHintTextView.Layout.tailOffset - TKHintTextView.Layout.tailSize.width / 2)
            }
        }
    }
}
