import SwiftUI
import TKUIKit
import UIKit

struct PriceImpactView: View {
    let presentation: PriceImpactPresentation

    var body: some View {
        VStack(spacing: 0) {
            SwiftUI.Image(uiImage: .TKUIKit.Icons.Size28.exclamationmarkTriangle)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: Layout.iconSize, height: Layout.iconSize)
                .foregroundColor(Color(uiColor: .Accent.red))
                .padding(.top, Layout.contentTopPadding)
                .padding(.bottom, Layout.titleTopPadding)

            Text(presentation.title)
                .font(Font(TKTextStyle.h2.font))
                .foregroundColor(Color(uiColor: .Text.primary))
                .multilineTextAlignment(.center)
                .padding(.bottom, Layout.subtitleTopPadding)

            Text(presentation.subtitle)
                .font(Font(TKTextStyle.body1.font))
                .foregroundColor(Color(uiColor: .Text.secondary))
                .multilineTextAlignment(.center)
                .padding(.bottom, Layout.descriptionTopPadding)

            Text(presentation.description)
                .font(Font(TKTextStyle.body1.font))
                .foregroundColor(Color(uiColor: .Text.secondary))
                .multilineTextAlignment(.center)
                .padding(.bottom, Layout.buttonsTopPadding)

            VStack(spacing: Layout.buttonsSpacing) {
                actionButton(
                    title: presentation.confirmButtonTitle,
                    titleColor: .Accent.red,
                    backgroundColor: .Background.contentAttention,
                    action: presentation.didTapConfirm
                )

                actionButton(
                    title: presentation.backButtonTitle,
                    titleColor: .Button.secondaryForeground,
                    backgroundColor: .Button.secondaryBackground,
                    action: presentation.didTapBack
                )
            }
            .padding(.bottom, Layout.bottomPadding)
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color(uiColor: .Background.page))
    }
}

private extension PriceImpactView {
    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let contentTopPadding: CGFloat = 8
        static let iconSize: CGFloat = 44
        static let titleTopPadding: CGFloat = 12
        static let subtitleTopPadding: CGFloat = 8
        static let descriptionTopPadding: CGFloat = 12
        static let buttonsTopPadding: CGFloat = 24
        static let buttonsSpacing: CGFloat = 12
        static let buttonHeight: CGFloat = 56
        static let bottomPadding: CGFloat = 16
    }

    func actionButton(
        title: String,
        titleColor: UIColor,
        backgroundColor: UIColor,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(Font(TKTextStyle.label1.font))
                .foregroundColor(Color(uiColor: titleColor))
                .frame(maxWidth: .infinity)
                .frame(height: Layout.buttonHeight)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(uiColor: backgroundColor))
                )
        }
        .buttonStyle(.plain)
    }
}
