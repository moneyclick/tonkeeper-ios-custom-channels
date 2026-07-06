import SwiftUI

extension View {
    func debugPreview(
        backgroundColor: Color = Color(uiColor: .Background.content)
    ) -> some View {
        modifier(DebugPreviewModifier(backgroundColor: backgroundColor))
    }
}

struct DebugPreviewModifier: ViewModifier {
    var backgroundColor: Color

    func body(content: Content) -> some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            content
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .center
                )
        }
    }
}
