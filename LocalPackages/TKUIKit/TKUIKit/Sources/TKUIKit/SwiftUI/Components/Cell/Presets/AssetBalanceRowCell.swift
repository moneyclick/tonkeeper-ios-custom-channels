import SwiftUI

public enum AssetBalanceRowCellConfig {
    case shimmer
    case content(AssetBalanceRowCellContent)
}

public struct AssetBalanceRowCellContent: Identifiable {
    public struct Delta: Equatable {
        public let text: String
        public let isPositive: Bool

        public init(
            text: String,
            isPositive: Bool
        ) {
            self.text = text
            self.isPositive = isPositive
        }
    }

    public enum DisplayMode: Equatable {
        case includingDiffs(
            balance: String,
            price: String,
            delta: Delta?,
            fiat: String,
            showsPin: Bool
        )
        case includingMarketData(
            marketCap: String,
            price: String,
            change: Delta?,
            showsPin: Bool
        )
        case includingSelection(
            balance: String,
            fiat: String,
            showsPin: Bool
        )
    }

    public let id: String
    public let title: String
    public let badge: String?
    public let displayMode: DisplayMode
    public let avatarImageSource: AssetAvatarViewImageSource

    public init(
        id: String,
        title: String,
        badge: String?,
        displayMode: DisplayMode,
        avatarImageSource: AssetAvatarViewImageSource
    ) {
        self.id = id
        self.title = title
        self.badge = badge
        self.displayMode = displayMode
        self.avatarImageSource = avatarImageSource
    }
}

public struct AssetBalanceRowCell: View {
    public let config: AssetBalanceRowCellConfig
    public let showsDivider: Bool
    public let action: (() -> Void)?

    public init(
        config: AssetBalanceRowCellConfig,
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
                style: .grouped,
                showsDivider: showsDivider,
                action: action
            ),
            leading: {
                CellAssetLeading {
                    AssetAvatarView(imageSource: avatarImageSource)
                }
            },
            center: {
                CellCenter(
                    primaryRow: {
                        CellCenterPrimaryRow(
                            config: primaryRowConfig
                        )
                    },
                    secondaryRow: {
                        CellCenterSecondaryRow(
                            config: secondaryRowConfig
                        )
                    }
                )
            },
            trailing: {
                if showsTrailingAccessory {
                    CellTrailingAccessory(
                        config: .init(
                            color: .Accent.blue,
                            icon: SwiftUI.Image(
                                uiImage: .TKUIKit.Icons.Size28.donemarkOutline
                            ),
                            iconSize: 28
                        )
                    )
                } else {
                    EmptyView()
                }
            }
        )
    }
}

private extension AssetBalanceRowCell {
    var content: AssetBalanceRowCellContent? {
        if case let .content(content) = config {
            return content
        }
        return nil
    }

    var avatarImageSource: AssetAvatarViewImageSource {
        switch config {
        case .shimmer:
            return .shimmer
        case let .content(content):
            return content.avatarImageSource
        }
    }

    var primaryRowConfig: CellCenterPrimaryRow.Config {
        switch config {
        case .shimmer:
            return .shimmer()
        case let .content(content):
            return .content(primaryRowContent(content))
        }
    }

    func primaryRowContent(_ content: AssetBalanceRowCellContent) -> CellCenterPrimaryRow.Content {
        let tags = content.badge.map { tag in
            [TKTagSwiftUIViewConfig(tagConfiguration: .tag(text: tag))]
        }

        switch content.displayMode {
        case let .includingDiffs(balance, _, _, _, showsPin):
            return .init(
                title: content.title,
                tags: tags,
                status: showsPin
                    ? .init(image: .TKUIKit.Icons.Size12.pin, size: 12)
                    : nil,
                value: .init(title: balance)
            )
        case let .includingMarketData(_, price, _, showsPin):
            return .init(
                title: content.title,
                tags: tags,
                status: showsPin
                    ? .init(image: .TKUIKit.Icons.Size12.pin, size: 12)
                    : nil,
                value: .init(title: price)
            )
        case .includingSelection:
            return .init(
                title: content.title,
                tags: tags
            )
        }
    }

    var secondaryRowConfig: CellCenterSecondaryRow.Config {
        switch config {
        case .shimmer:
            return .shimmer()
        case let .content(content):
            return .content(secondaryRowContent(content))
        }
    }

    func secondaryRowContent(_ content: AssetBalanceRowCellContent) -> CellCenterSecondaryRow.Content {
        switch content.displayMode {
        case let .includingDiffs(_, price, delta, fiat, _):
            return .init(
                value: .init(
                    title: price
                ),
                delta: delta.map {
                    .init(text: $0.text, isPositive: $0.isPositive)
                },
                accessory: .init(
                    title: fiat
                )
            )
        case let .includingMarketData(marketCap, _, change, _):
            return .init(
                value: .init(title: marketCap),
                accessory: change.map { change in
                    .init(
                        title: change.text,
                        color: Color(
                            uiColor: (change.isPositive) ? .Accent.green : .Accent.red
                        )
                    )
                }
            )
        case let .includingSelection(balance, fiat, _):
            return .init(
                value: .init(title: [balance, fiat].joined(separator: " · "))
            )
        }
    }

    var showsTrailingAccessory: Bool {
        guard let displayMode = content?.displayMode else {
            return false
        }

        switch displayMode {
        case .includingDiffs,
             .includingMarketData:
            return false
        case let .includingSelection(_, _, showsPin):
            return showsPin
        }
    }
}
