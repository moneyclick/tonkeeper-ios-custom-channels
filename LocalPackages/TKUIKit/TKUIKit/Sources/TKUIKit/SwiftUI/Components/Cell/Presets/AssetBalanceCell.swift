import SwiftUI

public enum AssetBalanceCellConfig {
    case shimmer
    case content(AssetBalanceCellContent)
}

public struct AssetBalanceCellContent {
    public var symbol: String
    public var chainTag: String?
    public var assetImageSource: AssetAvatarViewImageSource
    public var amountText: String
    public var convertedAmountText: String?

    public init(
        symbol: String,
        chainTag: String? = nil,
        assetImageSource: AssetAvatarViewImageSource,
        amountText: String,
        convertedAmountText: String? = nil
    ) {
        self.symbol = symbol
        self.chainTag = chainTag
        self.assetImageSource = assetImageSource
        self.amountText = amountText
        self.convertedAmountText = convertedAmountText
    }
}

public struct AssetBalanceCell: View {
    public var config: AssetBalanceCellConfig

    public init(
        config: AssetBalanceCellConfig
    ) {
        self.config = config
    }

    public var body: some View {
        Cell {
            CellAssetLeading {
                leading
            }
        } center: {
            CellCenter {
                CellCenterPrimaryRow(
                    config: primaryRowConfig
                )
            } secondaryRow: {
                CellCenterSecondaryRow(
                    config: secondaryRowConfig
                )
            }
        }
    }

    @ViewBuilder
    private var leading: some View {
        switch config {
        case .shimmer:
            AssetAvatarView(
                imageSource: .shimmer
            )
        case let .content(content):
            AssetAvatarView(
                imageSource: content.assetImageSource
            )
        }
    }

    private var primaryRowConfig: CellCenterPrimaryRow.Config {
        switch config {
        case .shimmer:
            .shimmer()
        case let .content(content):
            .content(
                .init(
                    title: content.amountText,
                    tags: content.chainTag.map { tag in
                        [TKTagSwiftUIViewConfig(tagConfiguration: .tag(text: tag))]
                    }
                )
            )
        }
    }

    private var secondaryRowConfig: CellCenterSecondaryRow.Config {
        if let secondaryRowText {
            .content(
                CellCenterSecondaryRow.Content(
                    value: .init(
                        title: secondaryRowText
                    )
                )
            )
        } else {
            .shimmer()
        }
    }

    private var secondaryRowText: String? {
        switch config {
        case .shimmer:
            nil
        case let .content(config):
            config.convertedAmountText
        }
    }
}
