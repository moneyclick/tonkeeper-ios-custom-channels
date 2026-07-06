import SwiftUI
import UIKit

public struct TKTooltipView: View {
    public struct Configuration: Equatable {
        public let title: String
        public let badgeTitle: String?

        public init(title: String, badgeTitle: String? = nil) {
            self.title = title
            self.badgeTitle = badgeTitle
        }
    }

    public let configuration: Configuration?
    public let position: HintPosition.Direction?

    public init(
        configuration: Configuration?,
        position: HintPosition.Direction? = nil
    ) {
        self.configuration = configuration
        self.position = position
    }

    public var body: some View {
        Group {
            if let configuration {
                HStack(alignment: .top, spacing: Layout.contentSpacing) {
                    if let badgeTitle = configuration.badgeTitle, !badgeTitle.isEmpty {
                        Text(badgeTitle.uppercased())
                            .foregroundColor(Color(UIColor.Accent.blue))
                            .textStyle(.body4Bold)
                            .padding(.top, Layout.badgeTopPadding)
                            .padding(.bottom, Layout.badgeBottomPadding)
                            .padding(.horizontal, Layout.badgeHorizontalPadding)
                            .background(Color(uiColor: .Constant.white))
                            .clipShape(RoundedRectangle(cornerRadius: Layout.badgeCornerRadius))
                    }

                    Text(configuration.title)
                        .foregroundColor(Color(UIColor.Constant.white))
                        .textStyle(.label2)
                        .lineLimit(1)
                }
                .padding(.top, Layout.topPadding)
                .padding(.leading, Layout.leadingPadding)
                .padding(.bottom, Layout.bottomPadding)
                .padding(.trailing, Layout.trailingPadding)
                .withTail(
                    appearance: Self.appearance,
                    parameters: Self.tailParameters,
                    direction: position
                )
            } else {
                Color.clear
            }
        }
    }
}

extension TKTooltipView: HintView {
    public static var tailParameters: HintTailParameters? {
        HintTailParameters(
            horizontalOffset: Layout.tailOffset,
            size: Layout.tailSize,
            tailCornerRadius: Layout.tailCornerRadius
        )
    }

    public static var appearance: HintAppearance {
        HintAppearance(
            backgroundColor: Color(uiColor: .Accent.blue),
            cornerRadius: Layout.cornerRadius,
            shadowColor: Color.black.opacity(0.04),
            shadowRadius: 8,
            shadowYOffset: 4
        )
    }
}

private extension TKTooltipView {
    enum Layout {
        static let contentSpacing: CGFloat = 6
        static let topPadding: CGFloat = 10
        static let leadingPadding: CGFloat = 14
        static let bottomPadding: CGFloat = 10
        static let trailingPadding: CGFloat = 16
        static let badgeTopPadding: CGFloat = 2.5
        static let badgeBottomPadding: CGFloat = 3.5
        static let badgeHorizontalPadding: CGFloat = 5
        static let badgeCornerRadius: CGFloat = 4
        static let cornerRadius: CGFloat = 10
        static let tailSize = CGSize(width: 12, height: 6)
        static let tailOffset: CGFloat = 24
        static let tailCornerRadius: CGFloat = 2
    }
}
