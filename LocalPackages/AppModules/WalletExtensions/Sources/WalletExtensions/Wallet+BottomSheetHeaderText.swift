import KeeperCore
import SwiftUI
import TKUIKit
import UIKit

public extension Wallet {
    func bottomSheetHeaderText(
        nameColor: UIColor = .Text.secondary,
        iconColor: UIColor = .Icon.primary
    ) -> Text {
        switch icon {
        case let .emoji(emoji):
            return Text("\(emoji) \(label)")
                .foregroundColor(Color(uiColor: nameColor))
        case let .icon(icon):
            guard let image = icon.image else {
                return Text(label)
                    .foregroundColor(Color(uiColor: nameColor))
            }

            return Text(Image(uiImage: image.withRenderingMode(.alwaysTemplate)))
                .foregroundColor(Color(uiColor: iconColor))
                + Text(" \(label)")
                .foregroundColor(Color(uiColor: nameColor))
        }
    }
}
