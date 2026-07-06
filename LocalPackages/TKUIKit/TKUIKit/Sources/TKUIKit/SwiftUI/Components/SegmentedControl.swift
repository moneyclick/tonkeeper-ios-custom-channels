import SwiftUI

private struct SegmentedControlStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(height: 40)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(uiColor: backgroundColor))
            )
    }

    private var backgroundColor: UIColor {
        UIColor {
            let scheme = TKThemeManager.shared.themeAppearance.colorScheme(for: $0.userInterfaceStyle)
            switch scheme {
            case is LightColorScheme:
                return scheme.backgroundContentAlternate
            case is DarkColorScheme:
                return scheme.backgroundTransparent
            default:
                return scheme.backgroundOverlayExtraLight
            }
        }
    }
}

private struct SegmentedControlButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.89 : 1)
            .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
    }
}

private struct SegmentBoundsPreferenceKey<Selection: Hashable>: PreferenceKey {
    static var defaultValue: [Selection: Anchor<CGRect>] {
        [:]
    }

    static func reduce(
        value: inout [Selection: Anchor<CGRect>],
        nextValue: () -> [Selection: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}

private extension View {
    func segmentedControlStyle() -> some View {
        modifier(SegmentedControlStyle())
    }
}

public struct SegmentedControlShimmer: View {
    public init() {}

    public var body: some View {
        ShimmerSwiftUIView()
            .frame(maxWidth: .infinity)
            .segmentedControlStyle()
    }
}

public struct SegmentedControl<Selection: Hashable>: View {
    private let segments: [Segment]
    private let initialSelection: Selection
    private let onSelectionChange: (Selection) -> Void

    @State private var selectedSegmentID: Selection

    public init(
        segments: [Segment],
        initialSelection: Selection,
        onSelectionChange: @escaping (Selection) -> Void
    ) {
        self.segments = segments
        self.initialSelection = initialSelection
        self.onSelectionChange = onSelectionChange
        _selectedSegmentID = State(initialValue: initialSelection)
    }

    public var body: some View {
        HStack(spacing: 1) {
            ForEach(segments) { segment in
                segmentButton(segment)
            }
        }
        .backgroundPreferenceValue(SegmentBoundsPreferenceKey<Selection>.self) { preferences in
            selectionBackground(preferences)
        }
        .padding(4)
        .segmentedControlStyle()
        .onChange(of: initialSelection) { initialSelection in
            guard selectedSegmentID != initialSelection else { return }
            setSelectedSegmentID(initialSelection)
        }
    }
}

public extension SegmentedControl {
    internal enum Layout {
        static var iconSize: CGFloat {
            20
        }
    }

    struct Icon {
        public var image: UIImage
        public var size: CGFloat

        public init(
            image: UIImage,
            size: CGFloat? = nil
        ) {
            self.image = image
            self.size = size ?? Layout.iconSize
        }
    }

    struct Segment: Identifiable {
        public var id: Selection
        public var title: String
        public var icon: Icon?

        public init(
            id: Selection,
            title: String,
            icon: Icon? = nil
        ) {
            self.id = id
            self.title = title
            self.icon = icon
        }
    }
}

private extension SegmentedControl {
    func segmentButton(_ segment: Segment) -> some View {
        Button {
            select(segment.id)
        } label: {
            segmentContent(segment)
        }
        .buttonStyle(SegmentedControlButtonStyle())
        .frame(maxWidth: .infinity)
        .anchorPreference(
            key: SegmentBoundsPreferenceKey<Selection>.self,
            value: .bounds
        ) { anchor in
            [segment.id: anchor]
        }
    }

    func selectionBackground(_ preferences: [Selection: Anchor<CGRect>]) -> some View {
        GeometryReader { proxy in
            if let anchor = preferences[selectedSegmentID] {
                let rect = proxy[anchor]
                Capsule(style: .continuous)
                    .fill(Color(uiColor: selectedItemBackgroundColor))
                    .frame(width: rect.width, height: rect.height)
                    .offset(x: rect.minX, y: rect.minY)
                    .animation(selectionChangeAnimation, value: selectedSegmentID)
            }
        }
    }

    func segmentContent(_ segment: Segment) -> some View {
        HStack(spacing: 4) {
            if let icon = segment.icon {
                Image(uiImage: icon.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: icon.size, height: icon.size)
            }
            Text(segment.title)
                .textStyle(.label2)
                .padding([.leading], 1)
                .foregroundStyle(Color(uiColor: foregroungColor))
        }
        .padding(.vertical, 7)
    }

    func select(_ segmentID: Selection) {
        guard selectedSegmentID != segmentID else { return }

        setSelectedSegmentID(segmentID)

        onSelectionChange(segmentID)
    }

    func setSelectedSegmentID(_ segmentID: Selection) {
        withAnimation(selectionChangeAnimation) {
            selectedSegmentID = segmentID
        }
    }

    private var selectionChangeAnimation: Animation {
        .spring(response: 0.28, dampingFraction: 0.84)
    }

    private var foregroungColor: UIColor {
        UIColor {
            let scheme = TKThemeManager.shared.themeAppearance.colorScheme(for: $0.userInterfaceStyle)
            switch scheme {
            case is LightColorScheme:
                return scheme.textPrimary
            default:
                return scheme.buttonPrimaryForeground
            }
        }
    }

    private var selectedItemBackgroundColor: UIColor {
        UIColor {
            let scheme = TKThemeManager.shared.themeAppearance.colorScheme(for: $0.userInterfaceStyle)
            switch scheme {
            case is LightColorScheme:
                return scheme.buttonPrimaryForeground
            default:
                return scheme.buttonTertiaryBackground
            }
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        SegmentedControl(
            segments: [
                SegmentedControl.Segment(
                    id: "1",
                    title: "2 Min",
                    icon: SegmentedControl<String>.Icon(
                        image: .TKUIKit.Icons.Size28.clock
                    )
                ),
                SegmentedControl.Segment(
                    id: "2",
                    title: "Top Losers"
                ),
            ],
            initialSelection: "1",
            onSelectionChange: { _ in }
        )
        SegmentedControlShimmer()
    }
    .padding(.horizontal, 24)
    .debugPreview()
}
