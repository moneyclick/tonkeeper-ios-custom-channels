import SwiftUI

public struct CellButtonModifier<V: View>: ButtonStyle {
    let builder: (_ isPressed: Bool) -> V

    init(
        @ViewBuilder builder: @escaping (_ isPressed: Bool) -> V
    ) {
        self.builder = builder
    }

    public func makeBody(configuration: Configuration) -> some View {
        builder(
            configuration.isPressed
        )
        .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
    }
}
