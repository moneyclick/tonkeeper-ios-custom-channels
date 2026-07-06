import SwiftUI
import UIKit

public struct TKBottomSheetConfiguration {
    public var cornerRadius: CGFloat
    public var overlayColor: UIColor
    public var backgroundColor: UIColor
    public var dismissOnOverlayTap: Bool
    public var sheetAnimation: Animation
    public var overlayAnimation: Animation

    public init(
        cornerRadius: CGFloat = 20,
        overlayColor: UIColor = .Background.overlayStrong,
        backgroundColor: UIColor = .Background.page,
        dismissOnOverlayTap: Bool = true,
        sheetAnimation: Animation = .interactiveSpring(
            response: 0.36,
            dampingFraction: 0.88,
            blendDuration: 0.12
        ),
        overlayAnimation: Animation = .easeOut(duration: 0.2)
    ) {
        self.cornerRadius = cornerRadius
        self.overlayColor = overlayColor
        self.backgroundColor = backgroundColor
        self.dismissOnOverlayTap = dismissOnOverlayTap
        self.sheetAnimation = sheetAnimation
        self.overlayAnimation = overlayAnimation
    }

    public static let `default` = TKBottomSheetConfiguration()
}

public extension View {
    func tkBottomSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        configuration: TKBottomSheetConfiguration = .default,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(
            TKBottomSheetBoolModifier(
                isPresented: isPresented,
                configuration: configuration,
                sheetContent: content
            )
        )
    }

    func tkBottomSheet<Item: Hashable, SheetContent: View>(
        item: Binding<Item?>,
        configuration: TKBottomSheetConfiguration = .default,
        @ViewBuilder content: @escaping (Item) -> SheetContent
    ) -> some View {
        modifier(
            TKBottomSheetItemModifier(
                item: item,
                configuration: configuration,
                sheetContent: content
            )
        )
    }
}

private struct TKBottomSheetBoolModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let configuration: TKBottomSheetConfiguration
    let sheetContent: () -> SheetContent

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { safeAreaGeometry in
                    GeometryReader { geometry in
                        ZStack(alignment: .bottom) {
                            ZStack {
                                if isPresented {
                                    TKBottomSheetDimmingLayer(
                                        configuration: configuration,
                                        dismiss: { isPresented = false }
                                    )
                                    .transition(.opacity)
                                }
                            }
                            .animation(configuration.overlayAnimation, value: isPresented)

                            ZStack(alignment: .bottom) {
                                if isPresented {
                                    TKBottomSheetContainer(
                                        configuration: configuration,
                                        bottomSafeAreaInset: safeAreaGeometry.safeAreaInsets.bottom,
                                        maxHeight: maxSheetHeight(
                                            geometry: geometry,
                                            safeAreaInsets: safeAreaGeometry.safeAreaInsets
                                        ),
                                        dismiss: { isPresented = false },
                                        sheetContent: sheetContent
                                    )
                                    .transition(.move(edge: .bottom))
                                }
                            }
                            .animation(configuration.sheetAnimation, value: isPresented)
                            .zIndex(1)
                        }
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height,
                            alignment: .bottom
                        )
                        .allowsHitTesting(isPresented)
                    }
                    .ignoresSafeArea()
                }
            }
    }
}

private struct TKBottomSheetItemModifier<Item: Hashable, SheetContent: View>: ViewModifier {
    @Binding var item: Item?
    let configuration: TKBottomSheetConfiguration
    let sheetContent: (Item) -> SheetContent

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { safeAreaGeometry in
                    GeometryReader { geometry in
                        ZStack(alignment: .bottom) {
                            ZStack {
                                if item != nil {
                                    TKBottomSheetDimmingLayer(
                                        configuration: configuration,
                                        dismiss: { self.item = nil }
                                    )
                                    .transition(.opacity)
                                }
                            }
                            .animation(configuration.overlayAnimation, value: item != nil)

                            ZStack(alignment: .bottom) {
                                if let item {
                                    TKBottomSheetContainer(
                                        configuration: configuration,
                                        bottomSafeAreaInset: safeAreaGeometry.safeAreaInsets.bottom,
                                        maxHeight: maxSheetHeight(
                                            geometry: geometry,
                                            safeAreaInsets: safeAreaGeometry.safeAreaInsets
                                        ),
                                        dismiss: { self.item = nil },
                                        sheetContent: { sheetContent(item) }
                                    )
                                    .id(item)
                                    .transition(.move(edge: .bottom))
                                }
                            }
                            .animation(configuration.sheetAnimation, value: item)
                            .zIndex(1)
                        }
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height,
                            alignment: .bottom
                        )
                        .allowsHitTesting(item != nil)
                    }
                    .ignoresSafeArea()
                }
            }
    }
}

private struct TKBottomSheetDimmingLayer: View {
    @Environment(\.colorScheme) private var colorScheme

    let configuration: TKBottomSheetConfiguration
    let dismiss: () -> Void

    var body: some View {
        Color.tkResolved(
            uiColor: configuration.overlayColor,
            colorScheme: colorScheme
        )
        .opacity(.dimmingPresentedOpacity)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture {
            guard configuration.dismissOnOverlayTap else { return }
            dismiss()
        }
    }
}

private struct TKBottomSheetContainer<SheetContent: View>: View {
    let configuration: TKBottomSheetConfiguration
    let bottomSafeAreaInset: CGFloat
    let maxHeight: CGFloat
    let dismiss: () -> Void
    let sheetContent: () -> SheetContent

    @GestureState private var dragOffset: CGFloat = .zero

    var body: some View {
        sheetSurface
            .frame(
                maxWidth: .infinity,
                maxHeight: maxHeight,
                alignment: .bottom
            )
            .offset(y: normalizedDragOffset(dragOffset))
            .animation(dragOffset == .zero ? configuration.sheetAnimation : nil, value: dragOffset)
            .accessibilityAddTraits(.isModal)
    }

    private var sheetSurface: some View {
        sheetContent()
            .frame(maxWidth: .infinity)
            .padding(.bottom, bottomSafeAreaInset + upwardDragStretch(dragOffset))
            .background(Color(uiColor: configuration.backgroundColor))
            .clipShape(
                RoundedRectExt(
                    radius: configuration.cornerRadius,
                    corners: [.topLeft, .topRight]
                )
            )
            .contentShape(Rectangle())
            .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 3, coordinateSpace: .global)
            .updating($dragOffset) { value, state, transaction in
                transaction.animation = nil
                state = value.translation.height
            }
            .onEnded { value in
                if shouldDismiss(translation: value.translation.height, predictedTranslation: value.predictedEndTranslation.height) {
                    dismiss()
                }
            }
    }

    private func normalizedDragOffset(_ offset: CGFloat) -> CGFloat {
        guard offset < 0 else {
            return offset
        }

        return max(offset / 3, -.maximumUpwardDragOffset)
    }

    private func upwardDragStretch(_ offset: CGFloat) -> CGFloat {
        max(-normalizedDragOffset(offset), 0)
    }

    private func shouldDismiss(translation: CGFloat, predictedTranslation: CGFloat) -> Bool {
        translation > .dismissDragOffset || predictedTranslation > .dismissPredictedDragOffset
    }
}

private extension CGFloat {
    static let dismissDragOffset: CGFloat = 60
    static let dismissPredictedDragOffset: CGFloat = 120
    static let maximumUpwardDragOffset: CGFloat = 24
}

private extension Double {
    static let dimmingPresentedOpacity: Double = 0.72
}

private func maxSheetHeight(
    geometry: GeometryProxy,
    safeAreaInsets: EdgeInsets
) -> CGFloat {
    max(geometry.size.height - safeAreaInsets.top, 0)
}

private extension Color {
    static func tkResolved(
        uiColor: UIColor,
        colorScheme: SwiftUI.ColorScheme
    ) -> Color {
        let style: UIUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        let resolvedColor = uiColor.resolvedColor(
            with: UITraitCollection(userInterfaceStyle: style)
        )

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard resolvedColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return Color(uiColor: resolvedColor)
        }

        return Color(
            .sRGB,
            red: Double(red),
            green: Double(green),
            blue: Double(blue),
            opacity: Double(alpha)
        )
    }
}
