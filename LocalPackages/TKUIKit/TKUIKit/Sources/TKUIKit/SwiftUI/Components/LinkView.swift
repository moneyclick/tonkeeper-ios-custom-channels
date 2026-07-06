import SwiftUI

public struct LinkView: View {
    let icon: Image
    let title: String
    let onOpen: () -> Void

    public init(
        icon: Image,
        title: String,
        onOpen: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.onOpen = onOpen
    }

    public var body: some View {
        Button {
            onOpen()
        } label: {
            HStack(spacing: Layout.contentSpacing) {
                VStack(spacing: 0) {
                    icon
                        .renderingMode(.template)
                        .foregroundStyle(Color(uiColor: .Text.primary))
                        .padding(.top, Layout.iconTopPadding)
                    Spacer()
                }
                VStack(spacing: 0) {
                    Text(title)
                        .textStyle(.label2)
                        .foregroundStyle(Color(uiColor: .Button.secondaryForeground))
                        .multilineTextAlignment(.leading)
                        .padding(.top, Layout.titleTopPadding)
                    Spacer()
                }
            }
            .padding(.horizontal, Layout.horizontalPadding)
            .frame(height: Layout.height)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(uiColor: .Button.secondaryBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

private extension LinkView {
    enum Layout {
        static let contentSpacing: CGFloat = 8
        static let iconTopPadding: CGFloat = 10
        static let titleTopPadding: CGFloat = 9
        static let horizontalPadding: CGFloat = 16
        static let height: CGFloat = 36
    }
}

#Preview {
    LinkView(
        icon: Image(
            uiImage: .TKUIKit.Icons.Size16.telegram
        ),
        title: "Community in Telegram",
        onOpen: {}
    )
    .debugPreview(
        backgroundColor: Color(uiColor: .Background.page)
    )
}
