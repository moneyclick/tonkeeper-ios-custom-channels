import SwiftUI

public struct CellTrailingAccessory: View {
    private let config: Config

    public init(config: Config) {
        self.config = config
    }

    public var body: some View {
        config.icon
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(
                width: config.iconSize,
                height: config.iconSize
            )
            .foregroundStyle(
                Color(uiColor: config.color)
            )
            .padding(Layout.insets)
    }
}

extension CellTrailingAccessory {
    enum Layout {
        static let insets = EdgeInsets(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: 16
        )
    }
}

public extension CellTrailingAccessory {
    struct Config {
        public var color: UIColor
        public var iconSize: CGFloat
        public var icon: Image

        public init(
            color: UIColor,
            icon: Image,
            iconSize: CGFloat = 28
        ) {
            self.color = color
            self.icon = icon
            self.iconSize = iconSize
        }
    }
}
