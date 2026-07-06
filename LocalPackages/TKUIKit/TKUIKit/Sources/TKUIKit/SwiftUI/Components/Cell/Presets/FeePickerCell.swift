import SwiftUI

public enum FeePickerCellConfig {
    case shimmer
    case content(FeePickerCellContent)
}

public struct FeePickerCellContent {
    public var leading: Leading
    public var title: String
    public var subtitle: String?
    public var badge: Badge?

    public init(
        leading: Leading,
        title: String,
        subtitle: String? = nil,
        badge: Badge? = nil
    ) {
        self.leading = leading
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
    }
}

public extension FeePickerCellContent {
    enum Leading {
        case assetAvatar(imageSource: AssetAvatarViewImageSource)
        case icon(
            image: UIImage,
            tintColor: UIColor,
            backgroundColor: UIColor
        )
    }

    struct Badge {
        public var text: String
        public var foreground: UIColor
        public var background: UIColor

        public init(
            text: String,
            foreground: UIColor,
            background: UIColor
        ) {
            self.text = text
            self.foreground = foreground
            self.background = background
        }
    }
}

public struct FeePickerCell: View {
    public var config: FeePickerCellConfig
    public var showsDivider: Bool
    public var action: (() -> Void)?

    public init(
        config: FeePickerCellConfig,
        showsDivider: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.config = config
        self.showsDivider = showsDivider
        self.action = action
    }

    public var body: some View {
        Cell(
            config: Cell.Config(
                style: .regular,
                showsDivider: showsDivider,
                action: cellAction
            ),
            leading: {
                CellAssetLeading {
                    leadingView
                }
            },
            center: {
                centerView
            }
        )
        .allowsHitTesting(isHitTestingAllowed)
    }
}

private extension FeePickerCell {
    enum Layout {
        static let iconSize: CGFloat = 28
        static let iconContainerSize: CGFloat = 44
    }

    var cellAction: (() -> Void)? {
        switch config {
        case .shimmer:
            nil
        case .content:
            action
        }
    }

    var isHitTestingAllowed: Bool {
        switch config {
        case .shimmer:
            false
        case .content:
            true
        }
    }

    @ViewBuilder
    var leadingView: some View {
        switch config {
        case .shimmer:
            AssetAvatarView(imageSource: .shimmer)
        case let .content(content):
            switch content.leading {
            case let .assetAvatar(imageSource):
                AssetAvatarView(imageSource: imageSource)
            case let .icon(image, tintColor, backgroundColor):
                ZStack {
                    Circle()
                        .fill(Color(uiColor: backgroundColor))
                        .frame(
                            width: Layout.iconContainerSize,
                            height: Layout.iconContainerSize
                        )

                    Image(uiImage: image)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color(uiColor: tintColor))
                        .frame(
                            width: Layout.iconSize,
                            height: Layout.iconSize
                        )
                }
            }
        }
    }

    @ViewBuilder
    var centerView: some View {
        switch config {
        case .shimmer:
            CellCenter {
                CellCenterPrimaryRow(
                    config: .shimmer()
                )
            } secondaryRow: {
                CellCenterSecondaryRow(
                    config: .shimmer()
                )
            }
        case let .content(content):
            if let subtitle = content.subtitle {
                CellCenter {
                    CellCenterPrimaryRow(
                        config: primaryRowConfig(content)
                    )
                } secondaryRow: {
                    CellCenterSecondaryRow(
                        config: .content(
                            .init(
                                value: .init(
                                    title: subtitle
                                )
                            )
                        )
                    )
                }
            } else {
                CellCenter {
                    CellCenterPrimaryRow(
                        config: primaryRowConfig(content)
                    )
                }
            }
        }
    }

    func primaryRowConfig(_ content: FeePickerCellContent) -> CellCenterPrimaryRow.Config {
        .content(
            .init(
                title: content.title,
                tags: content.badge.map { badge in
                    [TKTagSwiftUIViewConfig(
                        text: badge.text,
                        textColor: badge.foreground,
                        textPadding: UIEdgeInsets(top: 2.5, left: 5, bottom: 3.5, right: 5),
                        backgroundColor: badge.background,
                        borderColor: .clear,
                        backgroundPadding: UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
                    )]
                }
            )
        )
    }
}
