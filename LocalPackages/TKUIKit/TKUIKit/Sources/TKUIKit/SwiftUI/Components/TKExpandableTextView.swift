import SwiftUI
import UIKit

public struct TKExpandableTextView: View {
    private let text: String
    private let collapsedLineLimit: Int
    private let moreTitle: String

    @State private var isExpanded = false
    @State private var collapsedTextHeight: CGFloat = .zero
    @State private var expandedTextHeight: CGFloat = .zero

    public init(
        text: String,
        collapsedLineLimit: Int,
        moreTitle: String
    ) {
        self.text = text
        self.collapsedLineLimit = max(collapsedLineLimit, 1)
        self.moreTitle = moreTitle
    }

    public var body: some View {
        textView
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .bottomTrailing) {
                if showsMoreButton {
                    moreButton
                }
            }
            .background(measurementContent)
            .onPreferenceChange(TextHeightPreferenceKey.self) { heights in
                if let collapsed = heights[.collapsed] {
                    collapsedTextHeight = collapsed
                }
                if let expanded = heights[.expanded] {
                    expandedTextHeight = expanded
                }
            }
            .onChange(of: text) { _ in
                isExpanded = false
            }
            .onChange(of: collapsedLineLimit) { _ in
                isExpanded = false
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .padding(.vertical, Layout.verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                    .fill(Color(uiColor: .Background.content))
            )
    }
}

private extension TKExpandableTextView {
    var textView: some View {
        Text(text)
            .textStyle(Layout.textStyle)
            .foregroundStyle(Color(uiColor: .Text.primary))
            .multilineTextAlignment(.leading)
            .lineLimit(isExpanded ? nil : collapsedLineLimit)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    var showsMoreButton: Bool {
        !isExpanded && expandedTextHeight > collapsedTextHeight + Layout.heightTolerance
    }

    var measurementContent: some View {
        VStack(spacing: 0) {
            measurementText(lineLimit: collapsedLineLimit, kind: .collapsed)
            measurementText(lineLimit: nil, kind: .expanded)
        }
        .hidden()
        .allowsHitTesting(false)
    }

    func measurementText(
        lineLimit: Int?,
        kind: MeasurementKind
    ) -> some View {
        Text(text)
            .textStyle(Layout.textStyle)
            .foregroundStyle(Color.clear)
            .multilineTextAlignment(.leading)
            .lineLimit(lineLimit)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: TextHeightPreferenceKey.self,
                        value: [kind: proxy.size.height]
                    )
                }
            )
    }

    var moreButton: some View {
        Button {
            withAnimation(.easeInOut(duration: Layout.animationDuration)) {
                isExpanded = true
            }
        } label: {
            Text(moreTitle)
                .textStyle(Layout.textStyle)
                .foregroundStyle(Color(uiColor: .Text.accent))
                .padding(.leading, Layout.moreButtonLeadingInset)
                .background(
                    LinearGradient(
                        stops: [
                            .init(color: Color(uiColor: .Background.content).opacity(0), location: 0),
                            .init(color: Color(uiColor: .Background.content), location: 0.35),
                            .init(color: Color(uiColor: .Background.content), location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: Layout.moreButtonHeight, alignment: .bottom)
                .contentShape(Rectangle())
        }
        .buttonStyle(MoreButtonStyle())
    }

    enum Layout {
        static let textStyle: TKTextStyle = .body2
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 16
        static let animationDuration: CGFloat = 0.2
        static let heightTolerance: CGFloat = 0.5
        static let moreButtonHeight: CGFloat = 20
        static let moreButtonLeadingInset: CGFloat = 24
    }
}

private enum MeasurementKind: Hashable {
    case collapsed
    case expanded
}

private struct TextHeightPreferenceKey: PreferenceKey {
    static let defaultValue: [MeasurementKind: CGFloat] = [:]

    static func reduce(
        value: inout [MeasurementKind: CGFloat],
        nextValue: () -> [MeasurementKind: CGFloat]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct MoreButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.48 : 1)
    }
}

#Preview {
    VStack(spacing: 16) {
        TKExpandableTextView(
            text: "Toncoin is TON's native cryptocurrency and deeply integrated into the Telegram ecosystem. Use for Telegram Premium TON payments, network fees, staking, and asset transfers across apps and wallets built on TON.Toncoin is TON's native cryptocurrency and deeply integrated into the Telegram ecosystem. Use for Telegram Premium TON payments, network fees, staking, and asset transfers across apps and wallets built on TON.",
            collapsedLineLimit: 3,
            moreTitle: "More"
        )

        TKExpandableTextView(
            text: "Toncoin is TON's native cryptocurrency and deeply integrated into the Telegram ecosystem.",
            collapsedLineLimit: 5,
            moreTitle: "More"
        )
    }
    .padding(.horizontal, 16)
    .debugPreview(
        backgroundColor: Color(uiColor: .Background.page)
    )
}
