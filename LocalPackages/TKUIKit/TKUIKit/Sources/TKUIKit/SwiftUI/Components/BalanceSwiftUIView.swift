import SwiftUI

public enum BalanceViewConfig: Hashable {
    case content(BalanceViewContent)
    case shimmer
}

public struct BalanceViewContent: Hashable {
    public struct Balance: Hashable {
        public struct Amount: Hashable {
            public var leadingText: String?
            public var text: String
            public var color: UIColor

            public init(
                leadingText: String? = nil,
                text: String,
                color: UIColor = .Text.primary
            ) {
                self.leadingText = leadingText
                self.text = text
                self.color = color
            }
        }

        public enum State: Hashable {
            case amount(Amount)
            case secure(color: UIColor)
        }

        public var state: State

        public init(
            text: String,
            color: UIColor = .Text.primary
        ) {
            self.state = .amount(Amount(text: text, color: color))
        }

        public init(
            leadingText: String,
            text: String,
            color: UIColor = .Text.primary
        ) {
            self.state = .amount(Amount(leadingText: leadingText, text: text, color: color))
        }

        public static func secure(color: UIColor = .Text.primary) -> Balance {
            Balance(state: .secure(color: color))
        }

        private init(state: State) {
            self.state = state
        }
    }

    public struct BackupButton: Hashable {
        public var color: UIColor

        public init(color: UIColor) {
            self.color = color
        }
    }

    public var balance: Balance
    public var address: BalanceHeaderBalanceStatusViewConfig?
    public var battery: BatterySwiftUIViewConfig?
    public var backupButton: BackupButton?

    public init(
        balance: Balance,
        address: BalanceHeaderBalanceStatusViewConfig? = nil,
        battery: BatterySwiftUIViewConfig? = nil,
        backupButton: BackupButton? = nil
    ) {
        self.balance = balance
        self.address = address
        self.battery = battery
        self.backupButton = backupButton
    }
}

public struct BalanceSwiftUIView: View {
    public var config: BalanceViewConfig
    private let balanceAction: (() -> Void)?
    private let addressAction: (() -> Void)?
    private let batteryAction: (() -> Void)?
    private let backupAction: (() -> Void)?

    public init(
        config: BalanceViewConfig,
        balanceAction: (() -> Void)? = nil,
        addressAction: (() -> Void)? = nil,
        batteryAction: (() -> Void)? = nil,
        backupAction: (() -> Void)? = nil
    ) {
        self.config = config
        self.balanceAction = balanceAction
        self.addressAction = addressAction
        self.batteryAction = batteryAction
        self.backupAction = backupAction
    }

    public var body: some View {
        VStack(spacing: 0) {
            amountView

            addressView
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
        .padding(Layout.contentInsets)
        .frame(height: Layout.height)
    }
}

private extension BalanceSwiftUIView {
    @ViewBuilder
    var addressView: some View {
        switch config {
        case let .content(content):
            if let address = content.address {
                BalanceHeaderBalanceStatusView(
                    config: address,
                    action: addressAction
                )
                .frame(height: Layout.addressHeight)
                .padding(.bottom, Layout.addressBottomPadding)
            }
        case .shimmer:
            ShimmerSwiftUIView(config: .init(cornerRadius: .capsule))
                .frame(width: 107, height: 16)
                .padding(.top, Layout.addressTopPadding)
                .padding(.bottom, Layout.addressBottomPadding)
        }
    }
    
    var amountView: some View {
        Group {
            switch config {
            case let .content(content):
                amountContentView(content)
            case .shimmer:
                VStack(spacing: 0) {
                    ShimmerSwiftUIView(config: .init(cornerRadius: .capsule))
                        .frame(width: 220, height: 32)
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: Layout.amountHeight,
            maxHeight: Layout.amountHeight,
            alignment: .center
        )
    }
    
    @ViewBuilder
    func amountContentView(_ content: BalanceViewContent) -> some View {
        HStack(alignment: .center, spacing: 0) {
            button(
                action: balanceAction,
                highlightedOpacity: Layout.balanceHighlightedOpacity
            ) {
                balanceContentView(content)
            }

            batteryContentView(content)

            backupButtonContentView(content)
        }
    }

    @ViewBuilder
    func batteryContentView(_ content: BalanceViewContent) -> some View {
        if let battery = content.battery {
            button(
                action: batteryAction,
                highlightedOpacity: Layout.batteryHighlightedOpacity
            ) {
                BatterySwiftUIView(config: battery)
                    .padding(.top, Layout.batteryTopPadding)
                    .padding(.bottom, Layout.batteryBottomPadding)
                    .frame(height: Layout.amountHeight)
            }
            .padding(.leading, Layout.amountSpacing)
        }
    }

    @ViewBuilder
    func backupButtonContentView(_ content: BalanceViewContent) -> some View {
        if let backupButton = content.backupButton {
            button(
                action: backupAction,
                highlightedOpacity: Layout.backupHighlightedOpacity
            ) {
                Image(uiImage: .TKUIKit.Icons.Size12.informationCircle)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color(uiColor: backupButton.color))
                    .frame(
                        width: Layout.backupIconSide,
                        height: Layout.backupIconSide
                    )
                    .padding(Layout.backupIconPadding)
                    .background(
                        RoundedRectangle(
                            cornerRadius: Layout.backupCornerRadius,
                            style: .continuous
                        )
                        .fill(Color(uiColor: backupButton.color.withAlphaComponent(Layout.backupBackgroundAlpha)))
                    )
            }
            .padding(.trailing, Layout.backupTrailingPadding)
            .frame(height: Layout.amountHeight)
        }
    }

    @ViewBuilder
    func balanceContentView(_ content: BalanceViewContent) -> some View {
        switch content.balance.state {
        case let .amount(amount):
            HStack(alignment: .center, spacing: Layout.amountSpacing) {
                if let leadingText = amount.leadingText {
                    balanceText(leadingText, color: amount.color)
                        .fixedSize(horizontal: true, vertical: false)
                }

                balanceText(amount.text, color: amount.color)
            }
        case let .secure(color):
            secureBalanceView(color: color)
        }
    }

    @ViewBuilder
    func button<Content: View>(
        action: (() -> Void)?,
        highlightedOpacity: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if let action {
            SwiftUI.Button(action: action) {
                content()
            }
            .buttonStyle(BalanceViewButtonStyle(highlightedOpacity: highlightedOpacity))
        } else {
            content()
        }
    }

    func balanceText(_ text: String, color: UIColor) -> some View {
        Text(text)
            .textStyle(Layout.balanceTextStyle)
            .foregroundStyle(Color(uiColor: color))
            .lineLimit(1)
            .truncationMode(.tail)
            .multilineTextAlignment(.center)
            .frame(height: Layout.balanceTextStyle.lineHeight)
    }

    func secureBalanceView(color: UIColor) -> some View {
        Text(Layout.secureText)
            .textStyle(.num2)
            .foregroundStyle(Color(uiColor: color))
            .lineLimit(1)
            .padding(Layout.secureTextInsets)
            .background(Color(uiColor: .Button.secondaryBackground))
            .clipShape(Capsule())
            .frame(height: Layout.amountHeight)
    }
}

private struct BalanceViewButtonStyle: SwiftUI.ButtonStyle {
    let highlightedOpacity: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? highlightedOpacity : 1)
            .contentShape(Rectangle())
    }
}

private extension BalanceSwiftUIView {
    enum Layout {
        static let height: CGFloat = 132
        static let contentInsets = EdgeInsets(
            top: 28,
            leading: 16,
            bottom: 16,
            trailing: 16
        )
        static let amountHeight: CGFloat = 56
        static let amountSpacing: CGFloat = 8
        static let balanceTextStyle: TKTextStyle = .balance
        static let balanceHighlightedOpacity: CGFloat = 0.64
        static let batteryHighlightedOpacity: CGFloat = 0.44
        static let backupHighlightedOpacity: CGFloat = 0.48
        static let batteryTopPadding: CGFloat = 10
        static let batteryBottomPadding: CGFloat = 12
        static let backupIconSide: CGFloat = 12
        static let backupIconPadding: CGFloat = 4
        static let backupCornerRadius: CGFloat = 10
        static let backupTrailingPadding: CGFloat = 10
        static let backupBackgroundAlpha: CGFloat = 0.48
        static let secureText = "* * *"
        static let secureTextInsets = EdgeInsets(
            top: 5,
            leading: 16,
            bottom: 5,
            trailing: 16
        )
        static let addressHeight: CGFloat = TKTextStyle.body2.lineHeight
        static let addressTopPadding: CGFloat = 4
        static let addressBottomPadding: CGFloat = 8
    }
}
