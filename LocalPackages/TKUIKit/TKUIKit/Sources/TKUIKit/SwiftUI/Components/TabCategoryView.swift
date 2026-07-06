import SwiftUI
import UIKit

public struct TabCategoryView: View {
    let title: String
    let image: UIImage?
    let isSelected: Bool
    let action: () -> Void

    public init(
        title: String,
        image: UIImage? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.image = image
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack {
                Spacer()
                HStack(spacing: Layout.contentSpacing) {
                    if let image {
                        Image(uiImage: image)
                    }
                    Text(title)
                        .textStyle(.label2)
                }
                .foregroundStyle(
                    Color(
                        uiColor: isSelected
                            ? .Button.primaryForeground
                            : .Button.secondaryForeground
                    )
                )
                Spacer()
            }
            .padding(.horizontal, Layout.horizontalPadding)
        }
        .frame(height: Layout.height)
        .background(
            Capsule(style: .continuous)
                .fill(
                    Color(
                        uiColor: isSelected
                            ? .Accent.blue
                            : .Button.secondaryBackground
                    )
                )
        )
        .buttonStyle(.plain)
    }
}

private extension TabCategoryView {
    enum Layout {
        static let height: CGFloat = 32
        static let horizontalPadding: CGFloat = 12
        static let contentSpacing: CGFloat = 4
    }
}

#Preview {
    HStack(spacing: 12) {
        TabCategoryView(
            title: "All",
            image: UIImage(systemName: "star.fill"),
            isSelected: true,
            action: {}
        )
        TabCategoryView(
            title: "Crypto",
            isSelected: false,
            action: {}
        )
        TabCategoryView(
            title: "Stocks",
            isSelected: false,
            action: {}
        )
        TabCategoryView(
            title: "ETFs",
            isSelected: false,
            action: {}
        )
        Spacer()
    }
    .padding(.horizontal, 12)
    .debugPreview(
        backgroundColor: Color(uiColor: .Background.page)
    )
}
