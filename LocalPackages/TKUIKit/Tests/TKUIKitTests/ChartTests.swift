@testable import TKUIKit
import XCTest

@MainActor
final class ChartTests: XCTestCase {
    func testAnimatableChartVectorPadsShorterOperandWithLastValue() {
        let lhs = AnimatableChartVector(values: [0.1, 0.2, 0.3])
        let rhs = AnimatableChartVector(values: [0.4])

        let result = lhs + rhs

        assertEqual(result.values, [0.5, 0.6, 0.7])
    }

    func testAnimatableChartVectorScalingAffectsEachComponent() {
        var vector = AnimatableChartVector(values: [1, 2, 3])

        vector.scale(by: 0.5)

        assertEqual(vector.values, [0.5, 1, 1.5])
    }

    func testSmoothingResolvedTensionClampsIntoZeroOneRange() {
        XCTAssertEqual(TKLineChartCanvasView.Smoothing.none.resolvedTension, 0, accuracy: 0.0001)
        XCTAssertEqual(TKLineChartCanvasView.Smoothing.automatic.resolvedTension, 0.58, accuracy: 0.0001)
        XCTAssertEqual(TKLineChartCanvasView.Smoothing.tension(2).resolvedTension, 1, accuracy: 0.0001)
        XCTAssertEqual(TKLineChartCanvasView.Smoothing.tension(-1).resolvedTension, 0, accuracy: 0.0001)
    }

    func testVisualStyleDisablesSelectionForSkeleton() {
        XCTAssertTrue(TKLineChartCanvasView.VisualStyle.active.allowsSelection)
        XCTAssertTrue(TKLineChartCanvasView.VisualStyle.active.showsValueLabels)

        XCTAssertFalse(TKLineChartCanvasView.VisualStyle.skeleton.allowsSelection)
        XCTAssertFalse(TKLineChartCanvasView.VisualStyle.skeleton.showsValueLabels)
    }

    func testLineChartPointNormalizerSortsPointsByXAndKeepsOriginalIndices() {
        let points = LineChartPointNormalizer.normalize([
            MockCoordinate(x: 20, y: 200),
            MockCoordinate(x: 10, y: 100),
            MockCoordinate(x: 30, y: 300),
        ])

        XCTAssertEqual(points.map(\.sourceIndex), [1, 0, 2])
        assertEqual(points.map(\.point.x), [0, 0.5, 1])
    }

    func testLineChartPointSamplerPreservesBoundaryValuesForUnsortedInput() {
        let points = LineChartPointNormalizer.normalize([
            MockCoordinate(x: 20, y: 200),
            MockCoordinate(x: 10, y: 100),
            MockCoordinate(x: 30, y: 300),
        ])

        let sampledValues = LineChartPointSampler.sample(
            points: points,
            mode: .linear,
            sampleCount: 96
        )

        XCTAssertEqual(sampledValues.first ?? .zero, points.first?.point.y ?? .zero, accuracy: 0.0001)
        XCTAssertEqual(sampledValues.last ?? .zero, points.last?.point.y ?? .zero, accuracy: 0.0001)
    }

    func testChartSubstrateGridPositionsAlignWithXAxisLabelOffsets() {
        let positions = ChartSubstrateGridLayout.lineXPositions(
            width: 390,
            lineCount: ChartBottomPriceView.Layout.axisDivisionCount
        )

        assertEqual(positions, [39, 117, 195, 273, 351])
        XCTAssertEqual(
            positions[0] + ChartBottomPriceView.Layout.axisLabelHorizontalOffset,
            45,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            positions[2] + ChartBottomPriceView.Layout.axisLabelHorizontalOffset,
            201,
            accuracy: 0.0001
        )
    }

    func testChartSubstrateGridLayoutHandlesInvalidInput() {
        XCTAssertEqual(ChartSubstrateGridLayout.lineXPositions(width: 0, lineCount: 5), [])
        XCTAssertEqual(ChartSubstrateGridLayout.lineXPositions(width: 390, lineCount: 0), [])
    }

    func testRenderedChartPointSamplerUsesCurrentValueAtSteppedBreakpoint() {
        let yValue = RenderedChartPointSampler.yValue(
            at: 0.5,
            yValues: [0.1, 0.8, 0.2],
            mode: .stepped,
            smoothing: 0
        )

        XCTAssertEqual(yValue ?? .zero, 0.8, accuracy: 0.0001)
    }

    func testRenderedChartPointSamplerPreservesFirstAndLastValuesWithSmoothing() {
        let yValues: [CGFloat] = [0.2, 0.7, 0.4, 0.9]

        XCTAssertEqual(
            RenderedChartPointSampler.yValue(
                at: 0,
                yValues: yValues,
                mode: .linear,
                smoothing: 0.58
            ) ?? .zero,
            yValues.first ?? .zero,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            RenderedChartPointSampler.yValue(
                at: 1,
                yValues: yValues,
                mode: .linear,
                smoothing: 0.58
            ) ?? .zero,
            yValues.last ?? .zero,
            accuracy: 0.0001
        )
    }

    func testRendererSelectionReturnsOriginalIndexForUnsortedCoordinates() {
        let renderer = TKLineChartRenderer()
        var selectedIndex: Int?

        renderer.didSelectValue = { index in
            selectedIndex = index
        }
        renderer.setChartData(
            TKLineChartCanvasView.ChartData(
                mode: .linear,
                coordinates: [
                    MockCoordinate(x: 20, y: 200),
                    MockCoordinate(x: 10, y: 100),
                    MockCoordinate(x: 30, y: 300),
                ],
                smoothing: .automatic,
                style: .active
            )
        )

        renderer.updateSelection(at: CGPoint(x: 0, y: 20), in: CGSize(width: 300, height: 120))

        XCTAssertEqual(selectedIndex, 1)
    }

    func testGestureDirectionTreatsPredominantlyHorizontalMovementAsHorizontal() {
        XCTAssertTrue(
            TKLineChartGestureDirection.isHorizontal(
                translation: CGPoint(x: 24, y: 8)
            )
        )
    }

    func testGestureDirectionPrefersScrollWhenVerticalMovementIsGreaterOrEqual() {
        XCTAssertFalse(
            TKLineChartGestureDirection.isHorizontal(
                translation: CGPoint(x: 8, y: 24)
            )
        )
        XCTAssertFalse(
            TKLineChartGestureDirection.isHorizontal(
                translation: CGPoint(x: 12, y: 12)
            )
        )
    }

    private func assertEqual(_ lhs: [CGFloat], _ rhs: [CGFloat], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(lhs.count, rhs.count, file: file, line: line)
        for (lhsValue, rhsValue) in zip(lhs, rhs) {
            XCTAssertEqual(lhsValue, rhsValue, accuracy: 0.0001, file: file, line: line)
        }
    }

    private struct MockCoordinate: Coordinate {
        let x: Double
        let y: Double
    }
}
