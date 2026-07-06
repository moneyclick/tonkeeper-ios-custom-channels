import SwiftUI

private struct HintButtonPreviewPlayground: View {
    private let selectedDirection: RequestedDirection
    @State private var horizontalMode = HorizontalMode.relative
    @State private var horizontalValue = 0.0
    @State private var verticalOffset = 8.0
    @State private var maximumWidth = 220.0
    @State private var messageVariant = MessageVariant.long
    @State private var isSettingsPresented = false

    init(initialDirection: RequestedDirection) {
        selectedDirection = initialDirection
    }

    var body: some View {
        interactiveCoverage
            .padding(.vertical, 20)
            .ignoresSafeArea(.all)
            .debugPreview(backgroundColor: Color(uiColor: .Background.page))
    }

    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: Layout.controlSpacing) {
            VStack(alignment: .leading, spacing: Layout.controlLabelSpacing) {
                Text("Horizontal Mode")
                    .textStyle(.label2)
                    .foregroundStyle(Color(uiColor: .Text.secondary))

                Picker("Horizontal Mode", selection: $horizontalMode) {
                    ForEach(HorizontalMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            sliderRow(
                title: horizontalMode.sliderTitle,
                value: horizontalValueText,
                range: horizontalMode.range,
                step: horizontalMode.step,
                binding: $horizontalValue
            )

            sliderRow(
                title: "Vertical Offset",
                value: "\(Int(verticalOffset)) pt",
                range: 0 ... 48,
                step: 1,
                binding: $verticalOffset
            )

            sliderRow(
                title: "Maximum Width",
                value: "\(Int(maximumWidth)) pt",
                range: 120 ... 320,
                step: 10,
                binding: $maximumWidth
            )

            VStack(alignment: .leading, spacing: Layout.controlLabelSpacing) {
                Text("Message")
                    .textStyle(.label2)
                    .foregroundStyle(Color(uiColor: .Text.secondary))

                Picker("Message", selection: $messageVariant) {
                    ForEach(MessageVariant.allCases) { variant in
                        Text(variant.title).tag(variant)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var interactiveCoverage: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    previewButton("Top Left")
                    Spacer()
                    previewButton("Top Right")
                }

                Spacer(minLength: Layout.canvasSpacing)

                HStack {
                    Spacer()
                    previewButton("Center")
                    Spacer()
                }

                controlPanel
                    .padding(.vertical, 48)

                HStack {
                    previewButton("Bottom Left")
                    Spacer()
                    previewButton("Bottom Right")
                }
            }
            .padding(Layout.canvasPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func previewButton(_ title: String) -> some View {
        HintButton(configuration: activeConfiguration) { position in
            TKHintTextView(
                text: previewText(
                    anchor: title,
                    requested: selectedDirection.value,
                    resolved: position
                ),
                position: position
            )
        } label: {
            previewLabel(title)
        }
    }

    private func previewLabel(_ title: String) -> some View {
        Text(title)
            .textStyle(.body2)
            .foregroundStyle(Color(uiColor: .Text.primary))
            .padding(.horizontal, Layout.labelHorizontalPadding)
            .padding(.vertical, Layout.labelVerticalPadding)
            .background(
                Color(uiColor: .Background.contentTint)
                    .clipped()
            )
    }

    private func sliderRow(
        title: String,
        value: String,
        range: ClosedRange<Double>,
        step: Double,
        binding: Binding<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.controlLabelSpacing) {
            HStack {
                Text(title)
                    .textStyle(.label2)
                    .foregroundStyle(Color(uiColor: .Text.secondary))

                Spacer(minLength: Layout.minimumSpacer)

                Text(value)
                    .textStyle(.body2)
                    .foregroundStyle(Color(uiColor: .Text.primary))
            }

            Slider(
                value: binding,
                in: range,
                step: step
            )
            .tint(Color(uiColor: .Accent.blue))
        }
    }

    private func configuration(for direction: RequestedDirection) -> HintConfiguration {
        HintConfiguration(
            position: HintPosition(
                tailParameters: TKHintTextView.tailParameters,
                horizontal: horizontalPosition,
                vertical: .init(absolute: CGFloat(verticalOffset)),
                direction: direction.value
            ),
            maximumWidth: CGFloat(maximumWidth),
            animationStyle: .bouncing
        )
    }

    private var activeConfiguration: HintConfiguration {
        configuration(for: selectedDirection)
    }

    private var horizontalPosition: HintPosition.HorizontalPosition {
        switch horizontalMode {
        case .relative:
            .relative(CGFloat(horizontalValue))
        case .absolute:
            .absolute(CGFloat(horizontalValue))
        }
    }

    private var horizontalValueText: String {
        switch horizontalMode {
        case .relative:
            horizontalValue.formatted(.number.precision(.fractionLength(2)))
        case .absolute:
            "\(Int(horizontalValue)) pt"
        }
    }

    private func previewText(
        anchor: String,
        requested: HintPosition.Direction,
        resolved: HintPosition.Direction?
    ) -> String {
        let resolvedDirection = resolved ?? requested
        return [
            anchor,
            "Requested: \(RequestedDirection(direction: requested).title)",
            "Resolved: \(RequestedDirection(direction: resolvedDirection).title)",
            messageVariant.text,
        ]
        .joined(separator: "\n")
    }
}

private extension HintButtonPreviewPlayground {
    enum Layout {
        static let controlSpacing: CGFloat = 16
        static let controlLabelSpacing: CGFloat = 8
        static let minimumSpacer: CGFloat = 12
        static let canvasPadding: CGFloat = 24
        static let canvasSpacing: CGFloat = 16
        static let canvasCornerRadius: CGFloat = 24
        static let cardSpacing: CGFloat = 12
        static let labelHorizontalPadding: CGFloat = 14
        static let labelVerticalPadding: CGFloat = 10
        static let settingsHorizontalPadding: CGFloat = 14
        static let settingsVerticalPadding: CGFloat = 10
        static let popoverPadding: CGFloat = 16
        static let popoverWidth: CGFloat = 320
    }

    enum RequestedDirection: String, CaseIterable, Identifiable {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight

        init(direction: HintPosition.Direction) {
            switch direction {
            case .topLeft:
                self = .topLeft
            case .topRight:
                self = .topRight
            case .bottomLeft:
                self = .bottomLeft
            case .bottomRight:
                self = .bottomRight
            }
        }

        var id: Self {
            self
        }

        var title: String {
            switch self {
            case .topLeft:
                "Top Left"
            case .topRight:
                "Top Right"
            case .bottomLeft:
                "Bottom Left"
            case .bottomRight:
                "Bottom Right"
            }
        }

        var value: HintPosition.Direction {
            switch self {
            case .topLeft:
                .topLeft
            case .topRight:
                .topRight
            case .bottomLeft:
                .bottomLeft
            case .bottomRight:
                .bottomRight
            }
        }
    }

    enum HorizontalMode: String, CaseIterable, Identifiable {
        case relative
        case absolute

        var id: Self {
            self
        }

        var title: String {
            switch self {
            case .relative:
                "Relative"
            case .absolute:
                "Absolute"
            }
        }

        var sliderTitle: String {
            switch self {
            case .relative:
                "Horizontal Offset"
            case .absolute:
                "Horizontal Offset"
            }
        }

        var range: ClosedRange<Double> {
            switch self {
            case .relative:
                -1 ... 1
            case .absolute:
                -120 ... 120
            }
        }

        var step: Double {
            switch self {
            case .relative:
                0.05
            case .absolute:
                4
            }
        }
    }

    enum MessageVariant: String, CaseIterable, Identifiable {
        case short
        case medium
        case long

        var id: Self {
            self
        }

        var title: String {
            rawValue.capitalized
        }

        var text: String {
            switch self {
            case .short:
                "Short body."
            case .medium:
                "Two lines of helper copy to confirm the bubble size remains stable."
            case .long:
                "A longer helper message that stresses wrapping, preferredContentSize and window-edge fallback behaviour for the universal tooltip controller."
            }
        }
    }
}

#Preview("Top Left") {
    HintButtonPreviewPlayground(initialDirection: .topLeft)
}

#Preview("Top Right") {
    HintButtonPreviewPlayground(initialDirection: .topRight)
}

#Preview("Bottom Left") {
    HintButtonPreviewPlayground(initialDirection: .bottomLeft)
}

#Preview("Bottom Right") {
    HintButtonPreviewPlayground(initialDirection: .bottomRight)
}
