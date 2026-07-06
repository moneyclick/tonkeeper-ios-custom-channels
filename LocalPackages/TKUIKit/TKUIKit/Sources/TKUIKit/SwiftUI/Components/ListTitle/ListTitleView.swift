import SwiftUI

public struct ListTitleView: View {
    public var config: Config

    public init(config: Config) {
        self.config = config
    }

    public var body: some View {
        VStack(spacing: 0) {
            content
            Spacer(minLength: 0)
        }
        .frame(height: 48)
    }

    @ViewBuilder
    private var content: some View {
        switch config {
        case let .text(title, accessory):
            HStack(spacing: 0) {
                Text(title)
                    .textStyle(.label1)
                    .foregroundStyle(Color(uiColor: .Text.primary))
                    .padding(.top, Layout.topPadding)

                Spacer(minLength: 0)

                if let accessory {
                    Button {
                        accessory.action()
                    } label: {
                        Text(accessory.title)
                            .textStyle(.body2)
                            .foregroundStyle(Color(uiColor: .Accent.blue))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, Layout.accessoryTopPadding)
                }
            }
        case .shimmer:
            HStack(spacing: 0) {
                ShimmerSwiftUIView(config: .init(color: .Background.contentTint, cornerRadius: .value(12)))
                    .frame(width: 107, height: 24)
                    .padding(.top, Layout.shimmerTopPadding)
                Spacer(minLength: 0)
                ShimmerSwiftUIView(config: .init(color: .Background.contentTint, cornerRadius: .value(12)))
                    .frame(width: 55, height: 24)
                    .padding(.top, Layout.shimmerTopPadding)
            }
        }
    }
}

public extension ListTitleView {
    struct Accessory {
        var title: String
        var action: () -> Void

        public init(
            title: String,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.action = action
        }
    }

    enum Config {
        case text(String, accessory: Accessory? = nil)
        case shimmer
    }

    enum Layout {
        static let height: CGFloat = 48
        static let topPadding: CGFloat = 15
        static let accessoryTopPadding: CGFloat = 16
        static let shimmerTopPadding: CGFloat = 12
    }
}
