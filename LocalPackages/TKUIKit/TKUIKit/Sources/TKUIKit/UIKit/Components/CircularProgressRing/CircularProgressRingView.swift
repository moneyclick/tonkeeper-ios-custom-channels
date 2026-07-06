import UIKit

public protocol CircularProgressRingControlling: AnyObject {
    func start()
    func reset()
}

public final class CircularProgressRingView: UIView {
    public private(set) var displayLink: CADisplayLink?

    public var progress: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }

    public var duration: CFAbsoluteTime = 10

    public var lineWidth: CGFloat = 3 {
        didSet {
            setNeedsDisplay()
        }
    }

    public var backgroundFillColor: UIColor = .clear {
        didSet {
            setNeedsDisplay()
        }
    }

    public var onComplete: (() -> Void)?

    private var startTime = CFAbsoluteTimeGetCurrent()
    private var didFireComplete = false

    @objc
    private func handleDisplayLinkUpdate() {
        let value = CGFloat((CFAbsoluteTimeGetCurrent() - startTime) / duration)

        guard value < 1 else {
            progress = 1
            displayLink?.invalidate()
            displayLink = nil
            if !didFireComplete {
                didFireComplete = true
                onComplete?()
            }
            return
        }

        progress = value
    }

    override public func draw(_ rect: CGRect) {
        let trackColor = UIColor.Icon.primary.withAlphaComponent(0.32)
        let progressColor = UIColor.Icon.primary

        backgroundFillColor.setFill()
        UIRectFill(rect)

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = (min(rect.width, rect.height) - lineWidth) / 2
        guard radius > 0 else { return }

        let trackRect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        let trackPath = UIBezierPath(ovalIn: trackRect)
        trackPath.lineWidth = lineWidth
        trackColor.setStroke()
        trackPath.stroke()

        guard progress > 0 else { return }

        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi * min(progress, 1)
        let progressPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        progressPath.lineWidth = lineWidth
        progressPath.lineCapStyle = .round
        progressColor.setStroke()
        progressPath.stroke()
    }
}

extension CircularProgressRingView: CircularProgressRingControlling {
    public func start() {
        didFireComplete = false
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLinkUpdate))
        displayLink?.add(to: .main, forMode: .common)
        startTime = CFAbsoluteTimeGetCurrent()
    }

    public func reset() {
        progress = 0
        didFireComplete = false
        displayLink?.invalidate()
        displayLink = nil
    }
}
