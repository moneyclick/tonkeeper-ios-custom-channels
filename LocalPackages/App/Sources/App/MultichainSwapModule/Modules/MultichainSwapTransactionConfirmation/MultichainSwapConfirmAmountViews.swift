import SwiftUI
import TKUIKit

struct MultichainSwapConfirmAmountCard: View {
    let label: String
    let amountLine: String
    let tokenAvatarSource: AssetAvatarViewImageSource

    var body: some View {
        HStack(spacing: 12) {
            AssetAvatarView(imageSource: tokenAvatarSource, size: .small)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Font(TKTextStyle.body2.font))
                    .foregroundColor(Color(uiColor: .Text.secondary))

                Text(amountLine)
                    .font(Font(TKTextStyle.num2.font))
                    .foregroundColor(Color(uiColor: .Text.primary))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .Background.content))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
