import SwiftUI
import TKUIKit
import UIKit

struct MultichainSwapConfirmDetailRow: View {
    let title: String
    let value: String
    var onInfoTap: (() -> Void)? = nil
    var trailingIcon: UIImage? = nil
    var trailingAccessory: AnyView? = nil
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Text(title)
                    .font(Font(TKTextStyle.body1.font))
                    .foregroundColor(Color(uiColor: .Text.secondary))

                if let onInfoTap {
                    Button(action: onInfoTap) {
                        SwiftUI.Image(uiImage: UIImage.TKUIKit.Icons.Size16.informationCircle)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(Color(uiColor: .Icon.secondary))
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 8)

                HStack(spacing: 4) {
                    Text(value)
                        .font(Font(TKTextStyle.label1.font))
                        .foregroundColor(Color(uiColor: .Text.primary))
                        .multilineTextAlignment(.trailing)

                    if let trailingAccessory {
                        trailingAccessory
                    } else if let trailingIcon {
                        SwiftUI.Image(uiImage: trailingIcon)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(Color(uiColor: .Icon.secondary))
                    }
                }
            }
            .padding(16)

            if !isLast {
                Rectangle()
                    .fill(Color(uiColor: .Separator.common))
                    .frame(height: 1 / UIScreen.main.scale)
                    .padding(.leading, 16)
            }
        }
    }
}

struct MultichainSwapConfirmFeeRow: View {
    let title: String
    let value: String
    let method: String
    let subtitle: String

    let onMethodTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .trailing, spacing: 4) {
                HStack(alignment: .top, spacing: 6) {
                    Text(title)
                        .font(Font(TKTextStyle.body1.font))
                        .foregroundColor(Color(uiColor: .Text.secondary))
                    Spacer()
                    HStack(spacing: 0) {
                        networkFeeText
                            .font(Font(TKTextStyle.label1.font))
                            .foregroundColor(Color(uiColor: .Text.primary))
                        Button {
                            onMethodTap()
                        } label: {
                            HStack(spacing: 4) {
                                Text(method)
                                    .font(Font(TKTextStyle.label1.font))
                                    .multilineTextAlignment(.trailing)
                                SwiftUI.Image(uiImage: .TKUIKit.Icons.Size16.switch)
                            }
                            .foregroundColor(Color(uiColor: .Accent.blue))
                        }
                    }
                }

                Text(subtitle)
                    .font(Font(TKTextStyle.body2.font))
                    .foregroundColor(Color(uiColor: .Text.secondary))
            }
            .padding(16)

            Rectangle()
                .fill(Color(uiColor: .Separator.common))
                .frame(height: 1 / UIScreen.main.scale)
                .padding(.leading, 16)
        }
    }

    var networkFeeText: Text {
        Text("\(value)") + Text(" · ")
    }
}
