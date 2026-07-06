import KeeperCore
import TKCore
import TKLocalize
import TKUIKit
import TronSwift
import UIKit

extension TransactionConfirmationModel.ExtraType {
    var networkFeePickerTitle: String {
        switch self {
        case .default:
            TKLocales.ExtraType.ton
        case .battery:
            TKLocales.ExtraType.battery
        case let .gasless(token):
            token.symbol ?? token.name
        }
    }

    var networkFeePickerLeading: NetworkFeePickerItem.Leading {
        switch self {
        case .default:
            return .assetAvatar(
                imageSource: .image(UIImage.TKCore.Icons.Size44.tonLogo)
            )
        case .battery:
            return .icon(
                image: UIImage.TKUIKit.Icons.Size24.flash,
                tintColor: .Accent.green,
                backgroundColor: UIColor.Accent.green.withAlphaComponent(0.12)
            )
        case let .gasless(token):
            if token.symbol?.uppercased() == TRX.symbol.uppercased() {
                return .assetAvatar(
                    imageSource: .image(
                        UIImage.App.Currency.Vector.trc20.withRenderingMode(.alwaysOriginal)
                    )
                )
            }
            return .assetAvatar(
                imageSource: .url(token.imageURL)
            )
        }
    }
}
