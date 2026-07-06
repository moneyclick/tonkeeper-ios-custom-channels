import SwiftUI
import UIKit

public struct TabCategoriesView<Selection: Hashable>: View {
    private let items: [Item]
    private let shimmer: Bool
    private let initialSelection: Selection
    private let onSelectionChange: (Selection) -> Void
    private let contentInsets: EdgeInsets

    @State private var selectedItem: Selection

    public init(
        items: [Item],
        initialSelection: Selection,
        onSelectionChange: @escaping (Selection) -> Void,
        shimmer: Bool = false,
        insetsModifier: (inout EdgeInsets) -> Void = { _ in }
    ) {
        self.items = items
        self.initialSelection = initialSelection
        self.onSelectionChange = onSelectionChange
        self.shimmer = shimmer
        self.contentInsets = {
            var insets = Layout.insets
            insetsModifier(&insets)
            return insets
        }()
        _selectedItem = State(initialValue: initialSelection)
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Layout.itemSpacing) {
                ForEach(items) { item in
                    TabCategoryView(
                        title: item.title,
                        image: item.image,
                        isSelected: item.id == selectedItem
                    ) {
                        if item.isSelectable {
                            selectedItem = item.id
                        }
                        onSelectionChange(item.id)
                    }
                    .shimmer(shimmer, config: .init(cornerRadius: .capsule))
                }
                Spacer(minLength: 0)
            }
            .onChange(of: initialSelection) { initialSelection in
                guard selectedItem != initialSelection else { return }
                selectedItem = initialSelection
            }
            .padding(contentInsets)
        }
    }
}

public extension TabCategoriesView {
    struct Item: Identifiable {
        public var id: Selection
        public var title: String
        public var image: UIImage?
        public var isSelectable: Bool

        public init(
            id: Selection,
            title: String,
            image: UIImage? = nil,
            isSelectable: Bool = true
        ) {
            self.id = id
            self.title = title
            self.image = image
            self.isSelectable = isSelectable
        }
    }
}

extension TabCategoriesView {
    private enum Layout {
        static var itemSpacing: CGFloat {
            8
        }

        static var insets: EdgeInsets {
            EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16)
        }
    }
}
