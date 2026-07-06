import SwiftUI

public struct ListTitleViewPreviews: View {
    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                ListTitleView(
                    config: .text("Title")
                )
                .padding(.horizontal, Layout.rowHorizontalPadding)
                .background(Color(uiColor: .Background.content))

                ListTitleView(
                    config: .text(
                        "Title",
                        accessory: .init(
                            title: "See all",
                            action: {}
                        )
                    )
                )
                .padding(.horizontal, Layout.rowHorizontalPadding)
                .background(Color(uiColor: .Background.content))

                ListTitleView(
                    config: .shimmer
                )
                .padding(.horizontal, Layout.rowHorizontalPadding)
                .background(Color(uiColor: .Background.content))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            Color(uiColor: .Background.page)
                .ignoresSafeArea()
        )
    }
}

private extension ListTitleViewPreviews {
    enum Layout {
        static let contentVerticalPadding: CGFloat = 24
        static let sectionSpacing: CGFloat = 24
        static let rowHorizontalPadding: CGFloat = 16
        static let sectionHeaderBottomPadding: CGFloat = 12
    }
}

#Preview {
    ListTitleViewPreviews()
        .debugPreview(
            backgroundColor: Color(uiColor: .Background.page)
        )
}
