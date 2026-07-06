import SwiftUI
import UIKit

public struct TabCategoriesViewPreviews: View {
    @State private var selectedItem = "2"

    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.sectionSpacing) {
                TabCategoriesView(
                    items: items,
                    initialSelection: selectedItem,
                    onSelectionChange: { selectedItem in
                        self.selectedItem = selectedItem
                    }
                )

                TabCategoriesView(
                    items: items,
                    initialSelection: selectedItem,
                    onSelectionChange: { _ in },
                    shimmer: true
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            Color(uiColor: .Background.page)
                .ignoresSafeArea()
        )
    }
}

private extension TabCategoriesViewPreviews {
    var items: [TabCategoriesView<String>.Item] {
        [
            .init(
                id: "1",
                title: "first",
                image: .TKUIKit.Icons.Size16.checkmarkCircle
            ),
            .init(
                id: "2",
                title: "secoooooooond"
            ),
            .init(
                id: "3",
                title: "3"
            ),
            .init(
                id: "4",
                title: "TabCategoriesView.Item"
            ),
        ]
    }

    enum Layout {
        static let sectionSpacing: CGFloat = 24
    }
}

#Preview {
    TabCategoriesViewPreviews()
        .debugPreview(
            backgroundColor: Color(uiColor: .Background.page)
        )
}
