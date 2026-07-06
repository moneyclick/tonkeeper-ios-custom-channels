import SwiftUI

public struct BalanceHeaderBalanceStatusViewConfig: Hashable {
    public enum State: Hashable {
        case address(String, tags: [TKTagSwiftUIViewConfig])
        case updated(String)
        case connection(ConnectionStatus)
    }

    public struct ConnectionStatus: Hashable {
        public var title: String
        public var titleColor: UIColor
        public var isLoading: Bool

        public init(
            title: String,
            titleColor: UIColor,
            isLoading: Bool
        ) {
            self.title = title
            self.titleColor = titleColor
            self.isLoading = isLoading
        }
    }

    public var state: State

    public init(state: State) {
        self.state = state
    }
}

public struct BalanceHeaderBalanceStatusView: View {
    public var config: BalanceHeaderBalanceStatusViewConfig
    private let action: (() -> Void)?

    public init(
        config: BalanceHeaderBalanceStatusViewConfig,
        action: (() -> Void)? = nil
    ) {
        self.config = config
        self.action = action
    }

    public var body: some View {
        SwiftUI.Button(action: {
            action?()
        }) {
            content
        }
        .buttonStyle(BalanceHeaderBalanceStatusSwiftUIViewStyle())
    }
}

private extension BalanceHeaderBalanceStatusView {
    @ViewBuilder
    var content: some View {
        switch config.state {
        case let .address(text, tags):
            HStack(spacing: 0) {
                label(text)

                ForEach(Array(tags.enumerated()), id: \.offset) { _, tag in
                    TKTagSwiftUIView(config: tag)
                }
            }
            .frame(maxWidth: .infinity)
        case let .updated(text):
            label(text)
                .frame(maxWidth: .infinity)
        case let .connection(model):
            HStack(spacing: Layout.connectionSpacing) {
                Text(model.title)
                    .textStyle(.body2)
                    .foregroundStyle(Color(uiColor: model.titleColor))
                    .multilineTextAlignment(.center)

                if model.isLoading {
                    BalanceHeaderBalanceStatusLoaderView(
                        size: Layout.loaderSize,
                        tintColor: .Icon.secondary
                    )
                    .frame(
                        width: Layout.loaderSize.side,
                        height: Layout.loaderSize.side
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    func label(_ text: String) -> some View {
        Text(text)
            .textStyle(.body2)
            .foregroundStyle(Color(uiColor: .Text.secondary))
            .lineLimit(1)
            .truncationMode(.tail)
            .multilineTextAlignment(.center)
    }
}

private struct BalanceHeaderBalanceStatusSwiftUIViewStyle: SwiftUI.ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? BalanceHeaderBalanceStatusView.Layout.highlightedOpacity : 1)
            .contentShape(Rectangle())
    }
}

private struct BalanceHeaderBalanceStatusLoaderView: View {
    var size: Size
    var tintColor: UIColor
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color(uiColor: tintColor).opacity(Layout.bottomCircleOpacity),
                    lineWidth: size.circleWidth
                )
                .frame(
                    width: size.circleSide,
                    height: size.circleSide
                )

            Circle()
                .trim(from: 0, to: Layout.topCircleTrimEnd)
                .stroke(
                    Color(uiColor: tintColor),
                    style: StrokeStyle(
                        lineWidth: size.circleWidth,
                        lineCap: .round
                    )
                )
                .frame(
                    width: size.circleSide,
                    height: size.circleSide
                )
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: Layout.rotationDuration)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
        }
        .frame(
            width: size.side,
            height: size.side
        )
        .onAppear {
            isAnimating = true
        }
        .onDisappear {
            isAnimating = false
        }
    }
}

private extension BalanceHeaderBalanceStatusView {
    enum Layout {
        static let highlightedOpacity: CGFloat = 0.48
        static let connectionSpacing: CGFloat = 4
        static let loaderSize: BalanceHeaderBalanceStatusLoaderView.Size = .xSmall
    }
}

private extension BalanceHeaderBalanceStatusLoaderView {
    enum Size {
        case xSmall

        var side: CGFloat {
            switch self {
            case .xSmall:
                12
            }
        }

        var circleSide: CGFloat {
            switch self {
            case .xSmall:
                10
            }
        }

        var circleWidth: CGFloat {
            switch self {
            case .xSmall:
                2
            }
        }
    }

    enum Layout {
        static let bottomCircleOpacity: CGFloat = 0.32
        static let topCircleTrimEnd: CGFloat = 0.25
        static let rotationDuration: TimeInterval = 1
    }
}
