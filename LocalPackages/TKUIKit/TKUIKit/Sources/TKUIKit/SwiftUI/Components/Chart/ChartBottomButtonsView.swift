import SwiftUI

public struct ChartBottomButtonsView: View {
    private let config: Config

    public init(
        config: Config
    ) {
        self.config = config
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                switch config {
                case let .buttons(buttons):
                    ForEach(Array(buttons.enumerated()), id: \.offset) { _, button in
                        ButtonView(
                            config: ButtonView.Config(
                                title: button.title,
                                size: .small,
                                layoutMode: .fill,
                                appearance: button.isSelected ? .secondary : .secondaryOverlay,
                                action: button.tapAction
                            )
                        )
                    }
                case let .shimmer(count):
                    HStack(spacing: 8) {
                        ForEach(0 ..< count, id: \.self) { _ in
                            ButtonView(
                                config: ButtonView.Config(
                                    title: " ",
                                    size: .small,
                                    layoutMode: .fill,
                                    appearance: .secondary,
                                    action: {}
                                )
                            )
                            .shimmer(true, config: .init(cornerRadius: .capsule))
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(Layout.contentInsets)
            Spacer(minLength: 0)
        }
        .frame(height: Layout.height)
    }
}

public extension ChartBottomButtonsView {
    enum Layout {
        static let height: CGFloat = 68

        static let contentInsets = EdgeInsets(
            top: 16,
            leading: 16,
            bottom: 0,
            trailing: 16
        )
    }

    enum Config {
        public struct Button {
            public let title: String
            public let isSelected: Bool
            public let tapAction: () -> Void

            public init(
                title: String,
                isSelected: Bool,
                tapAction: @escaping () -> Void
            ) {
                self.title = title
                self.isSelected = isSelected
                self.tapAction = tapAction
            }
        }

        case buttons([Button])
        case shimmer(count: Int)
    }
}
