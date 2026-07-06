import SwiftUI

public struct ModalCardHeaderPreviews: View {
    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                DefaultModalCardHeader(
                    config: DefaultModalCardHeader.Config(
                        leftIcon: .close(),
                        title: DefaultModalCardHeader.Title(
                            text: "Title",
                            alignment: .center
                        ),
                        rightIcon: .close()
                    )
                )
                DefaultModalCardHeader(
                    config: DefaultModalCardHeader.Config(
                        leftIcon: .close(),
                        title: DefaultModalCardHeader.Title(
                            text: "Tesla",
                            alignment: .center
                        ),
                        subtitle: DefaultModalCardHeader.Subtitle(
                            text: "Tokenized Stock",
                            color: .Accent.blue,
                            icon: nil
                        ),
                        rightIcon: .close()
                    )
                )
                DefaultModalCardHeader(
                    config: DefaultModalCardHeader.Config(
                        leftIcon: .close(),
                        title: DefaultModalCardHeader.Title(
                            text: "Tesla",
                            alignment: .center
                        ),
                        subtitle: DefaultModalCardHeader.Subtitle(
                            text: "Tokenized Stock",
                            color: .Accent.blue,
                            icon: DefaultModalCardHeader.SubtitleIcon(
                                image: .TKUIKit.Icons.Size12.informationCircle,
                                size: 12,
                                topPadding: 3
                            )
                        ),
                        rightIcon: .close()
                    )
                )

                DefaultModalCardHeader(
                    config: DefaultModalCardHeader.Config(
                        title: DefaultModalCardHeader.Title(
                            text: "Title",
                            alignment: .leading
                        ),
                        rightIcon: .close()
                    )
                )
                DefaultModalCardHeader(
                    config: DefaultModalCardHeader.Config(
                        rightIcon: .close()
                    )
                )
                DefaultModalCardHeader(
                    config: DefaultModalCardHeader.Config(
                        rightIcon: .close(),
                        height: .compact
                    )
                )
            }
        }
        .background(
            Color(uiColor: .Background.content)
                .ignoresSafeArea()
        )
    }
}

#Preview {
    ModalCardHeaderPreviews()
        .debugPreview(
            backgroundColor: Color(uiColor: .Background.page)
        )
}
