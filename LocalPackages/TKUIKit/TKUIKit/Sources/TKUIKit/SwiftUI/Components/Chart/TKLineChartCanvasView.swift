import SwiftUI

public protocol Coordinate {
    var x: Double { get }
    var y: Double { get }
}

@MainActor
public struct TKLineChartCanvasView: View {
    private let chartData: ChartData
    private let scenario: Scenario

    @StateObject private var interactionState = InteractionState()

    public init(
        chartData: ChartData,
        scenario: Scenario = .nonInteractive
    ) {
        self.chartData = chartData
        self.scenario = scenario
    }

    public var body: some View {
        switch scenario {
        case let .interactive(interaction):
            interactiveContent(interaction: interaction)
        case .nonInteractive:
            staticContent
        }
    }

    private func interactiveContent(interaction: Interaction) -> some View {
        GeometryReader { geometry in
            TKLineChartContentView(renderer: interactionState.renderer)
                .contentShape(Rectangle())
                .overlay {
                    TKLineChartGestureOverlay(
                        minimumPressDuration: Layout.minimumPressDuration,
                        isEnabled: chartData.style.allowsSelection,
                        onSelectionBegan: { location in
                            interactionState.updateSelection(at: location, in: geometry.size)
                        },
                        onSelectionChanged: { location in
                            interactionState.updateSelection(at: location, in: geometry.size)
                        },
                        onSelectionEnded: {
                            interactionState.finishDragging()
                        }
                    )
                }
        }
        .background(Color.clear)
        .task(id: RenderToken(chartData: chartData)) {
            interactionState.updateCallbacks(
                interaction: interaction
            )
            interactionState.updateChartData(chartData)
        }
        .onDisappear {
            interactionState.finishDragging()
        }
    }

    private var staticContent: some View {
        let renderer = makeStaticRenderer()
        return TKLineChartContentView(renderer: renderer)
            .background(Color.clear)
    }

    private func makeStaticRenderer() -> TKLineChartRenderer {
        let renderer = TKLineChartRenderer()
        renderer.setChartData(chartData)
        return renderer
    }
}

public extension TKLineChartCanvasView {
    enum Scenario {
        case nonInteractive
        case interactive(Interaction)
    }

    struct Interaction {
        public let didSelectValue: (Int) -> Void
        public let didDeselectValue: () -> Void
        public let didStartDragging: () -> Void
        public let didEndDragging: () -> Void

        public init(
            didSelectValue: @escaping (Int) -> Void,
            didDeselectValue: @escaping () -> Void = {},
            didStartDragging: @escaping () -> Void = {},
            didEndDragging: @escaping () -> Void = {}
        ) {
            self.didSelectValue = didSelectValue
            self.didDeselectValue = didDeselectValue
            self.didStartDragging = didStartDragging
            self.didEndDragging = didEndDragging
        }
    }

    enum ChartMode: Sendable {
        case linear
        case stepped
    }

    enum Smoothing: Equatable, Sendable {
        case none
        case automatic
        case tension(CGFloat)

        var resolvedTension: CGFloat {
            switch self {
            case .none:
                return 0
            case .automatic:
                return 0.58
            case let .tension(value):
                return min(max(value, 0), 1)
            }
        }
    }

    enum VisualStyle: Equatable, Sendable {
        case active
        case skeleton

        var allowsSelection: Bool {
            self == .active
        }

        var showsValueLabels: Bool {
            self == .active
        }
    }

    struct ChartData {
        public let mode: ChartMode
        public let coordinates: [Coordinate]
        public let smoothing: Smoothing
        public let style: VisualStyle

        public init(
            mode: ChartMode,
            coordinates: [Coordinate],
            smoothing: Smoothing = .automatic,
            style: VisualStyle = .active
        ) {
            self.mode = mode
            self.coordinates = coordinates
            self.smoothing = smoothing
            self.style = style
        }
    }
}

private extension TKLineChartCanvasView {
    enum Layout {
        static let minimumPressDuration = 0.3
    }

    @MainActor
    final class InteractionState: ObservableObject {
        let renderer = TKLineChartRenderer()

        func updateCallbacks(interaction: Interaction) {
            renderer.didSelectValue = interaction.didSelectValue
            renderer.didDeselectValue = interaction.didDeselectValue
            renderer.didStartDragging = interaction.didStartDragging
            renderer.didEndDragging = interaction.didEndDragging
        }

        func updateChartData(_ chartData: ChartData) {
            renderer.setChartData(chartData)
        }

        func updateSelection(at location: CGPoint, in size: CGSize) {
            renderer.updateSelection(at: location, in: size)
        }

        func finishDragging() {
            renderer.finishDragging()
        }
    }
}

private struct RenderToken: Equatable {
    let mode: TKLineChartCanvasView.ChartMode
    let smoothing: CGFloat
    let style: TKLineChartCanvasView.VisualStyle
    let points: [CGPoint]

    init(chartData: TKLineChartCanvasView.ChartData) {
        mode = chartData.mode
        smoothing = chartData.smoothing.resolvedTension
        style = chartData.style
        points = chartData.coordinates.map { coordinate in
            CGPoint(x: coordinate.x, y: coordinate.y)
        }
    }
}
