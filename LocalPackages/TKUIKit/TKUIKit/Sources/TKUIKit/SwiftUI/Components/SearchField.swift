import SwiftUI

public struct SearchField: View {
    let contentInsets: EdgeInsets
    let title: String
    @Binding var text: String
    let isFocused: FocusState<Bool>.Binding?
    let allowsTextInput: Bool
    let shimmer: Bool

    public init(
        insetsModifier: (inout EdgeInsets) -> Void = { _ in },
        title: String,
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding? = nil,
        allowsTextInput: Bool = true,
        shimmer: Bool = false
    ) {
        contentInsets = {
            var insets = Layout.edgeInsets
            insetsModifier(&insets)
            return insets
        }()
        _text = text
        self.title = title
        self.isFocused = isFocused
        self.allowsTextInput = allowsTextInput
        self.shimmer = shimmer
    }

    public var body: some View {
        HStack(spacing: 12) {
            SwiftUI.Image(uiImage: .TKUIKit.Icons.Size16.magnifyingGlass)
                .renderingMode(.template)
                .foregroundStyle(Color(uiColor: .Icon.secondary))

            if allowsTextInput {
                TextField("", text: $text, prompt: Text(title).foregroundColor(Color(uiColor: .Text.secondary)))
                    .font(Font(UIFont.montserratMedium(size: 16)))
                    .foregroundColor(Color(uiColor: .Text.primary))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .tint(Color(uiColor: .Accent.blue))
                    .applyTradeSearchFocus(isFocused)
            } else {
                Text(text.isEmpty ? title : text)
                    .font(Font(UIFont.montserratMedium(size: 16)))
                    .foregroundStyle(
                        Color(uiColor: text.isEmpty ? .Text.secondary : .Text.primary)
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if allowsTextInput, !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    SwiftUI.Image(uiImage: .TKUIKit.Icons.Size16.xmarkCircle)
                        .renderingMode(.template)
                        .foregroundStyle(Color(uiColor: .Icon.secondary))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .Background.content))
        )
        .shimmer(shimmer)
        .padding(contentInsets)
    }
}

extension SearchField {
    enum Layout {
        static let edgeInsets: EdgeInsets = EdgeInsets(
            top: 16,
            leading: 16,
            bottom: 16,
            trailing: 16
        )
    }
}

private extension View {
    @ViewBuilder
    func applyTradeSearchFocus(_ binding: FocusState<Bool>.Binding?) -> some View {
        if let binding {
            focused(binding)
        } else {
            self
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        SearchField(
            title: "Search by ticker or name",
            text: .constant("")
        )
        SearchField(
            title: "Search by ticker or name",
            text: .constant("123")
        )
        SearchField(
            title: "Search by ticker or name",
            text: .constant(""),
            allowsTextInput: false
        )
    }
    .padding(.horizontal, 12)
    .debugPreview(
        backgroundColor: Color(uiColor: .Background.page)
    )
}
