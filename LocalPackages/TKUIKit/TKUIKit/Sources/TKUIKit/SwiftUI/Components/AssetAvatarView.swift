import Kingfisher
import SwiftUI

public enum AssetAvatarViewImageSource: Sendable, Equatable {
    case url(URL?, chainIcon: UIImage? = nil)
    case image(UIImage?, chainIcon: UIImage? = nil)
    case shimmer

    var chainIcon: UIImage? {
        switch self {
        case let .url(_, chainIcon):
            chainIcon
        case let .image(_, chainIcon):
            chainIcon
        case .shimmer:
            nil
        }
    }
}

public enum ChainIconPosition: Sendable {
    case leading
    case trailing
}

public struct AssetAvatarView: View {
    public enum Size: Sendable {
        case extraSmall
        case small
        case regular
        case large
        case extraLarge
    }

    public struct Configuration: Sendable, Equatable {
        public let imageSize: CGFloat
        public let chainIconSize: CGFloat
        public let chainIconPadding: CGFloat
        public let chainIconOffsetX: CGFloat
        public let chainIconOffsetY: CGFloat

        public init(
            imageSize: CGFloat,
            chainIconSize: CGFloat,
            chainIconPadding: CGFloat,
            chainIconOffsetX: CGFloat,
            chainIconOffsetY: CGFloat
        ) {
            self.imageSize = imageSize
            self.chainIconSize = chainIconSize
            self.chainIconPadding = chainIconPadding
            self.chainIconOffsetX = chainIconOffsetX
            self.chainIconOffsetY = chainIconOffsetY
        }
    }

    let imageSource: AssetAvatarViewImageSource
    let configuration: Configuration
    let chainIconPosition: ChainIconPosition

    public init(
        imageSource: AssetAvatarViewImageSource,
        size: Size? = nil,
        chainIconPosition: ChainIconPosition? = nil
    ) {
        self.init(
            imageSource: imageSource,
            configuration: (size ?? .small).configuration,
            chainIconPosition: chainIconPosition
        )
    }

    public init(
        imageSource: AssetAvatarViewImageSource,
        configuration: Configuration,
        chainIconPosition: ChainIconPosition? = nil
    ) {
        self.imageSource = imageSource
        self.configuration = configuration
        self.chainIconPosition = chainIconPosition ?? .trailing
    }

    struct ChainIconShape: Shape {
        var chainIconPosition: ChainIconPosition
        var configuration: Configuration

        nonisolated func path(in rect: CGRect) -> Path {
            let chainIconSize = configuration.chainIconSize

            let cutoutDiameter = (chainIconSize + configuration.chainIconPadding * 2)
            let bigCenter = CGPoint(x: rect.midX, y: rect.midY)
            let bigRadius = min(rect.width, rect.height) / 2
            let cutoutRect: CGRect
            switch chainIconPosition {
            case .leading:
                cutoutRect = CGRect(
                    x: rect.minX - configuration.chainIconOffsetX - configuration.chainIconPadding,
                    y: rect.maxY - cutoutDiameter + configuration.chainIconOffsetY + configuration.chainIconPadding,
                    width: cutoutDiameter,
                    height: cutoutDiameter
                )
            case .trailing:
                cutoutRect = CGRect(
                    x: rect.maxX - cutoutDiameter + configuration.chainIconOffsetX + configuration.chainIconPadding,
                    y: rect.maxY - cutoutDiameter + configuration.chainIconOffsetY + configuration.chainIconPadding,
                    width: cutoutDiameter,
                    height: cutoutDiameter
                )
            }
            let cutoutCenter = CGPoint(x: cutoutRect.midX, y: cutoutRect.midY)
            let cutoutRadius = cutoutRect.width / 2

            guard let intersections = intersections(
                firstCenter: bigCenter,
                firstRadius: bigRadius,
                secondCenter: cutoutCenter,
                secondRadius: cutoutRadius
            ) else {
                let path = UIBezierPath(ovalIn: rect)
                if distance(from: bigCenter, to: cutoutCenter) < bigRadius - cutoutRadius {
                    path.append(UIBezierPath(ovalIn: cutoutRect).reversing())
                }
                return Path(path.cgPath)
            }

            let firstIntersection = intersections.first
            let secondIntersection = intersections.second

            let bigStartAngle = angle(from: bigCenter, to: firstIntersection)
            let bigEndAngle = angle(from: bigCenter, to: secondIntersection)
            let bigClockwise = arcMidpoint(
                center: bigCenter,
                radius: bigRadius,
                startAngle: bigStartAngle,
                endAngle: bigEndAngle,
                clockwise: true
            )
            .map { !contains($0, center: cutoutCenter, radius: cutoutRadius) } ?? true

            let cutoutStartAngle = angle(from: cutoutCenter, to: secondIntersection)
            let cutoutEndAngle = angle(from: cutoutCenter, to: firstIntersection)
            let cutoutClockwise = arcMidpoint(
                center: cutoutCenter,
                radius: cutoutRadius,
                startAngle: cutoutStartAngle,
                endAngle: cutoutEndAngle,
                clockwise: true
            )
            .map { contains($0, center: bigCenter, radius: bigRadius) } ?? false

            let path = UIBezierPath()
            path.move(to: firstIntersection)
            path.addArc(
                withCenter: bigCenter,
                radius: bigRadius,
                startAngle: bigStartAngle,
                endAngle: bigEndAngle,
                clockwise: bigClockwise
            )
            path.addArc(
                withCenter: cutoutCenter,
                radius: cutoutRadius,
                startAngle: cutoutStartAngle,
                endAngle: cutoutEndAngle,
                clockwise: cutoutClockwise
            )
            path.close()

            return Path(path.cgPath)
        }

        private nonisolated func intersections(
            firstCenter: CGPoint,
            firstRadius: CGFloat,
            secondCenter: CGPoint,
            secondRadius: CGFloat
        ) -> (first: CGPoint, second: CGPoint)? {
            let centerDistance = distance(from: firstCenter, to: secondCenter)
            guard centerDistance > 0,
                  centerDistance < firstRadius + secondRadius,
                  centerDistance > abs(firstRadius - secondRadius)
            else {
                return nil
            }

            let a = (
                firstRadius * firstRadius
                    - secondRadius * secondRadius
                    + centerDistance * centerDistance
            ) / (2 * centerDistance)
            let hSquared = firstRadius * firstRadius - a * a
            guard hSquared >= 0 else {
                return nil
            }

            let h = sqrt(hSquared)
            let directionX = (secondCenter.x - firstCenter.x) / centerDistance
            let directionY = (secondCenter.y - firstCenter.y) / centerDistance
            let basePoint = CGPoint(
                x: firstCenter.x + a * directionX,
                y: firstCenter.y + a * directionY
            )
            let offset = CGPoint(
                x: -directionY * h,
                y: directionX * h
            )

            return (
                CGPoint(x: basePoint.x + offset.x, y: basePoint.y + offset.y),
                CGPoint(x: basePoint.x - offset.x, y: basePoint.y - offset.y)
            )
        }

        private nonisolated func distance(from start: CGPoint, to end: CGPoint) -> CGFloat {
            hypot(end.x - start.x, end.y - start.y)
        }

        private nonisolated func angle(from center: CGPoint, to point: CGPoint) -> CGFloat {
            atan2(point.y - center.y, point.x - center.x)
        }

        private nonisolated func arcMidpoint(
            center: CGPoint,
            radius: CGFloat,
            startAngle: CGFloat,
            endAngle: CGFloat,
            clockwise: Bool
        ) -> CGPoint? {
            let delta = angleDelta(
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: clockwise
            )
            guard delta > 0 else {
                return nil
            }

            let midpointAngle = clockwise
                ? startAngle + delta / 2
                : startAngle - delta / 2
            return CGPoint(
                x: center.x + radius * cos(midpointAngle),
                y: center.y + radius * sin(midpointAngle)
            )
        }

        private nonisolated func angleDelta(
            startAngle: CGFloat,
            endAngle: CGFloat,
            clockwise: Bool
        ) -> CGFloat {
            let fullTurn = CGFloat.pi * 2
            let rawDelta = clockwise
                ? endAngle - startAngle
                : startAngle - endAngle
            let normalized = rawDelta.truncatingRemainder(dividingBy: fullTurn)
            return normalized >= 0 ? normalized : normalized + fullTurn
        }

        private nonisolated func contains(
            _ point: CGPoint,
            center: CGPoint,
            radius: CGFloat
        ) -> Bool {
            distance(from: point, to: center) < radius
        }
    }

    private var size: CGFloat {
        configuration.imageSize
    }

    public var body: some View {
        ZStack {
            if imageSource.chainIcon != nil {
                contentView
                    .frame(width: size, height: size)
                    .background(Color(uiColor: .Background.contentTint))
                    .clipShape(
                        ChainIconShape(
                            chainIconPosition: chainIconPosition,
                            configuration: configuration
                        )
                    )
            } else {
                contentView
                    .frame(width: size, height: size)
                    .background(Color(uiColor: .Background.contentTint))
                    .clipShape(Circle())
            }
            if let chainIcon = imageSource.chainIcon {
                let chainIconSize = configuration.chainIconSize
                Image(uiImage: chainIcon)
                    .resizable()
                    .frame(width: chainIconSize, height: chainIconSize)
                    .offset(
                        x: {
                            switch chainIconPosition {
                            case .leading:
                                (chainIconSize - size) / 2 - configuration.chainIconOffsetX
                            case .trailing:
                                (size - chainIconSize) / 2 + configuration.chainIconOffsetX
                            }
                        }(),
                        y: (size - chainIconSize) / 2 + configuration.chainIconOffsetY
                    )
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch imageSource {
        case let .url(url, _):
            if let url {
                URLAvatarImageView(
                    url: url,
                    size: size
                )
            } else {
                Self.imageContentView(
                    for: .TKUIKit.Icons.Size44.placeholder,
                    size: size
                )
            }
        case let .image(image, _):
            Self.imageContentView(
                for: image ?? .TKUIKit.Icons.Size44.placeholder,
                size: size
            )
        case .shimmer:
            ShimmerSwiftUIView(config: shimmerConfig)
        }
    }

    fileprivate static func imageContentView(for image: UIImage, size: CGFloat) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

extension AssetAvatarView.Size {
    var configuration: AssetAvatarView.Configuration {
        switch self {
        case .extraSmall:
            AssetAvatarView.Configuration(
                imageSize: 24,
                chainIconSize: 12,
                chainIconPadding: 1.5,
                chainIconOffsetX: 2,
                chainIconOffsetY: 2
            )
        case .small:
            AssetAvatarView.Configuration(
                imageSize: 44,
                chainIconSize: 18,
                chainIconPadding: 2,
                chainIconOffsetX: 4,
                chainIconOffsetY: 4
            )
        case .regular:
            AssetAvatarView.Configuration(
                imageSize: 56,
                chainIconSize: 20,
                chainIconPadding: 2,
                chainIconOffsetX: 4,
                chainIconOffsetY: 4
            )
        case .large:
            AssetAvatarView.Configuration(
                imageSize: 72,
                chainIconSize: 24,
                chainIconPadding: 4,
                chainIconOffsetX: -4,
                chainIconOffsetY: 4
            )
        case .extraLarge:
            AssetAvatarView.Configuration(
                imageSize: 96,
                chainIconSize: 32,
                chainIconPadding: 4,
                chainIconOffsetX: 4,
                chainIconOffsetY: 4
            )
        }
    }
}

extension AssetAvatarView {
    private struct URLAvatarImageView: View {
        let url: URL
        let size: CGFloat

        @State private var didFail = false

        var body: some View {
            Group {
                if didFail {
                    AssetAvatarView.imageContentView(
                        for: .TKUIKit.Icons.Size44.placeholder,
                        size: size
                    )
                } else {
                    KFImage
                        .url(url)
                        .setProcessor(
                            DownsamplingImageProcessor(
                                size: CGSize(
                                    width: size * UIScreen.main.scale,
                                    height: size * UIScreen.main.scale
                                )
                            )
                        )
                        .loadDiskFileSynchronously()
                        .fade(duration: 0)
                        .placeholder {
                            ShimmerSwiftUIView(config: shimmerConfig)
                        }
                        .onSuccess { _ in
                            didFail = false
                        }
                        .onFailure { _ in
                            didFail = true
                        }
                        .cancelOnDisappear(true)
                        .resizable()
                        .scaledToFill()
                }
            }
        }
    }
}

private var shimmerConfig: ShimmerSwiftUIView.Config {
    ShimmerSwiftUIView.Config(color: .Background.contentTint)
}

#Preview {
    VStack(spacing: 24) {
        AssetAvatarView(
            imageSource: .url(URL(string: "https://cryptologos.cc/logos/bitcoin-btc-logo.png?v=041")!)
        )

        AssetAvatarView(
            imageSource: .url(nil, chainIcon: .TKUIKit.Icons.Size20.tonChain),
            chainIconPosition: .leading
        )

        AssetAvatarView(
            imageSource: .image(.TKUIKit.Icons.Size44.btcChain, chainIcon: .TKUIKit.Icons.Size20.tonChain)
        )

        AssetAvatarView(
            imageSource: .shimmer
        )

        HStack(alignment: .bottom, spacing: 12) {
            AssetAvatarView(
                imageSource: .image(.TKUIKit.Icons.Size44.btcChain, chainIcon: .TKUIKit.Icons.Size20.tonChain),
                size: .extraSmall
            )

            AssetAvatarView(
                imageSource: .image(.TKUIKit.Icons.Size44.btcChain, chainIcon: .TKUIKit.Icons.Size20.tonChain),
                size: .small
            )

            AssetAvatarView(
                imageSource: .image(.TKUIKit.Icons.Size44.btcChain, chainIcon: .TKUIKit.Icons.Size20.tonChain),
                size: .regular
            )

            AssetAvatarView(
                imageSource: .image(.TKUIKit.Icons.Size44.btcChain, chainIcon: .TKUIKit.Icons.Size20.tonChain),
                size: .large
            )

            AssetAvatarView(
                imageSource: .image(.TKUIKit.Icons.Size44.btcChain, chainIcon: .TKUIKit.Icons.Size20.tonChain),
                size: .extraLarge
            )
        }

        SwapPairAvatarView(
            left: .image(.TKUIKit.Icons.Size44.btcChain, chainIcon: .TKUIKit.Icons.Size20.tonChain),
            right: .image(.TKUIKit.Icons.Size44.btcChain, chainIcon: .TKUIKit.Icons.Size20.tonChain)
        )
    }
    .debugPreview()
}
