import SwiftUI
import UIKit

public enum TransactionCellConfig: Sendable, Equatable {
    case shimmer
    case content(TransactionCellContent)
}

public struct TransactionCellContent: Sendable, Equatable {
    public var icon: Icon
    public var title: String
    public var subtitle: Subtitle
    public var amount: Amount
    public var accessory: Accessory
    public var details: Details?
    public var nftPreview: NftPreview?
    public var messages: [Message]
    public var showsDivider: Bool

    public init(
        icon: Icon,
        title: String,
        subtitle: Subtitle,
        amount: Amount,
        accessory: Accessory,
        details: Details? = nil,
        nftPreview: NftPreview? = nil,
        messages: [Message] = [],
        showsDivider: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.accessory = accessory
        self.details = details
        self.nftPreview = nftPreview
        self.messages = messages
        self.showsDivider = showsDivider
    }
}

public extension TransactionCellContent {
    struct Icon: Sendable, Equatable {
        public var image: UIImage
        public var tintColor: Color
        public var backgroundColor: Color

        public init(
            image: UIImage,
            tintColor: Color,
            backgroundColor: Color = Color(uiColor: .Background.contentTint)
        ) {
            self.image = image
            self.tintColor = tintColor
            self.backgroundColor = backgroundColor
        }

        public static var received: Icon {
            Icon(
                image: .TKUIKit.Icons.Size28.trayArrowDown,
                tintColor: Color(uiColor: .Icon.secondary)
            )
        }

        public static var sent: Icon {
            Icon(
                image: .TKUIKit.Icons.Size28.trayArrowUp,
                tintColor: Color(uiColor: .Icon.secondary)
            )
        }

        public static var pending: Icon {
            Icon(
                image: .TKUIKit.Icons.Size28.clockOutline,
                tintColor: Color(uiColor: .Accent.orange)
            )
        }
    }
}

public extension TransactionCellContent {
    struct Amount: Sendable, Equatable {
        public var title: String
        public var style: AmountStyle

        public init(
            title: String,
            style: AmountStyle
        ) {
            self.title = title
            self.style = style
        }
    }

    enum AmountStyle: Sendable, Equatable {
        case primary
        case positive
        case negative
        case secondary
        case tertiary
        case warning
    }
}

public extension TransactionCellContent {
    enum SubtitleStyle: Sendable, Equatable {
        case primary
        case disabled
    }

    struct Subtitle: Sendable, Equatable {
        public var text: String
        public var style: SubtitleStyle

        public init(
            text: String,
            style: SubtitleStyle
        ) {
            self.text = text
            self.style = style
        }
    }
}

public extension TransactionCellContent {
    struct Accessory: Sendable, Equatable {
        public var text: String
        public var textStyle: TKTextStyle
        public var color: Color

        public init(
            text: String,
            textStyle: TKTextStyle = .body2,
            color: Color = Color(uiColor: .Text.secondary)
        ) {
            self.text = text
            self.textStyle = textStyle
            self.color = color
        }
    }
}

public extension TransactionCellContent {
    struct DetailsTitle: Sendable, Equatable {
        public var text: String
        public var color: Color

        public init(
            text: String,
            color: Color = Color(uiColor: .Text.secondary)
        ) {
            self.text = text
            self.color = color
        }
    }

    struct DetailsAccessory: Sendable, Equatable {
        public var text: String
        public var textStyle: TKTextStyle
        public var color: Color

        public init(
            text: String,
            textStyle: TKTextStyle = .body2,
            color: Color = Color(uiColor: .Text.secondary)
        ) {
            self.text = text
            self.textStyle = textStyle
            self.color = color
        }
    }

    struct Details: Sendable, Equatable {
        public var title: DetailsTitle?
        public var accessory: DetailsAccessory?

        public init(
            title: DetailsTitle? = nil,
            accessory: DetailsAccessory? = nil
        ) {
            self.title = title
            self.accessory = accessory
        }
    }
}

public extension TransactionCellContent {
    typealias NftId = String

    struct NftPreview: Sendable, Equatable {
        public var id: NftId
        public var image: UIImage
        public var title: String
        public var subtitle: String
        public var subtitleColor: Color
        public var isVerified: Bool

        public init(
            id: NftId,
            image: UIImage,
            title: String,
            subtitle: String,
            subtitleColor: Color = Color(uiColor: .Text.secondary),
            isVerified: Bool
        ) {
            self.id = id
            self.image = image
            self.title = title
            self.subtitle = subtitle
            self.subtitleColor = subtitleColor
            self.isVerified = isVerified
        }
    }
}

public extension TransactionCellContent {
    enum MessageStyle: Sendable, Hashable {
        case compact
        case regular
    }

    struct Message: Sendable, Hashable {
        public var id: String
        public var text: String
        public var style: MessageStyle

        public init(
            id: String,
            text: String,
            style: MessageStyle = .regular
        ) {
            self.id = id
            self.text = text
            self.style = style
        }
    }
}

public struct TransactionCell: View {
    public var config: TransactionCellConfig
    public var onTap: () -> Void
    public var onTapNft: (TransactionCellContent.NftId) -> Void

    public init(
        config: TransactionCellConfig,
        onTap: @escaping () -> Void = {},
        onTapNft: @escaping (TransactionCellContent.NftId) -> Void = { _ in }
    ) {
        self.config = config
        self.onTap = onTap
        self.onTapNft = onTapNft
    }

    public var body: some View {
        Cell(
            config: .init(
                style: .grouped,
                showsDivider: showsDivider,
                verticalAlignment: .top,
                action: onTap
            ),
            leading: {
                CellAssetLeading {
                    leadingContent
                        .frame(
                            width: Layout.iconSize,
                            height: Layout.iconSize
                        )
                        .clipShape(Circle())
                }
            },
            center: {
                CellCenter(
                    primaryRow: CellCenterPrimaryRow(
                        config: primaryRowConfig
                    ),
                    secondaryRow: VStack(alignment: .leading, spacing: 0) {
                        CellCenterSecondaryRow(
                            config: secondaryRowConfig
                        )
                        switch config {
                        case .shimmer:
                            EmptyView()
                        case let .content(content):
                            if let details = content.details {
                                detailsView(details)
                                    .padding(.top, Layout.detailRowTopPadding)
                            }
                            if let nftPreview = content.nftPreview {
                                nftPreviewView(nftPreview)
                                    .padding(.top, Layout.nftPreviewTopPadding)
                            }
                            ForEach(content.messages, id: \.self) { content in
                                message(content)
                            }
                        }
                    }
                )
                .padding(.top, Layout.centerTopPadding)
            }
        )
    }

    private var showsDivider: Bool {
        switch config {
        case .shimmer:
            false
        case let .content(content):
            content.showsDivider
        }
    }

    enum Layout {
        static let iconSize: CGFloat = 44
        static let centerTopPadding: CGFloat = 2
        static let detailRowTopPadding: CGFloat = 3
        static let supplementaryTopInset: CGFloat = 8
        static let nftPreviewTopPadding: CGFloat = 9
    }
}

// MARK: - Leading

extension TransactionCell {
    @ViewBuilder
    private var leadingContent: some View {
        switch config {
        case .shimmer:
            ShimmerSwiftUIView()
        case let .content(content):
            ZStack(alignment: .center) {
                Image(uiImage: content.icon.image)
                    .renderingMode(.template)
                    .foregroundStyle(content.icon.tintColor)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(content.icon.backgroundColor)
        }
    }
}

// MARK: - Primary Row

extension TransactionCell {
    private var primaryRowConfig: CellCenterPrimaryRow.Config {
        switch config {
        case .shimmer:
            .shimmer()
        case let .content(content):
            .content(
                .init(
                    title: content.title,
                    value: CellCenterPrimaryRow.ValueConfig(
                        title: content.amount.title,
                        color: Color(uiColor: amountColor)
                    )
                )
            )
        }
    }

    private var amountColor: UIColor {
        switch config {
        case .shimmer:
            .Text.primary
        case let .content(content):
            switch content.amount.style {
            case .primary:
                .Text.primary
            case .positive:
                .Accent.green
            case .negative:
                .Accent.red
            case .secondary:
                .Text.secondary
            case .tertiary:
                .Text.tertiary
            case .warning:
                .Accent.orange
            }
        }
    }
}

// MARK: - Secondary Row

extension TransactionCell {
    private var secondaryRowConfig: CellCenterSecondaryRow.Config {
        switch config {
        case .shimmer:
            .shimmer()
        case let .content(content):
            .content(
                .init(
                    value: .init(
                        title: content.subtitle.text,
                        textColor: secondaryRowSubtitleText,
                        truncationMode: .middle
                    ),
                    accessory: CellCenterSecondaryRow.AccessoryConfig(
                        title: content.accessory.text,
                        textStyle: content.accessory.textStyle,
                        color: content.accessory.color
                    )
                )
            )
        }
    }

    private var secondaryRowSubtitleText: UIColor {
        switch config {
        case .shimmer:
            .Text.secondary
        case let .content(content):
            switch content.subtitle.style {
            case .primary:
                .Text.secondary
            case .disabled:
                .Text.tertiary
            }
        }
    }
}

// MARK: - Details

extension TransactionCell {
    func detailsView(_ content: TransactionCellContent.Details) -> some View {
        HStack(spacing: 0) {
            if let title = content.title {
                Text(title.text)
                    .textStyle(.body2)
                    .foregroundStyle(title.color)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if let accessory = content.accessory {
                Text(accessory.text)
                    .textStyle(accessory.textStyle)
                    .foregroundStyle(accessory.color)
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}

// MARK: - NFT Preview

extension TransactionCell {
    private enum NftPreviewLayout {
        static let imageSize: CGFloat = 64
        static let cornerRadius: CGFloat = 12
        static let previewTopPadding: CGFloat = 1
        static let textSpacing: CGFloat = 2
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 7
        static let verificationSpacing: CGFloat = 4
        static let verificationIconSize: CGFloat = 16
    }

    func nftPreviewView(_ preview: TransactionCellContent.NftPreview) -> some View {
        Button {
            onTapNft(preview.id)
        } label: {
            nftPreviewContent(preview)
        }
        .buttonStyle(.plain)
    }

    func nftPreviewContent(_ preview: TransactionCellContent.NftPreview) -> some View {
        HStack(spacing: 0) {
            Image(uiImage: preview.image)
                .resizable()
                .scaledToFill()
                .frame(
                    width: NftPreviewLayout.imageSize,
                    height: NftPreviewLayout.imageSize
                )
                .clipped()

            VStack(alignment: .leading, spacing: NftPreviewLayout.textSpacing) {
                Text(preview.title)
                    .textStyle(.body2)
                    .foregroundStyle(Color(uiColor: .Text.primary))
                    .lineLimit(1)

                HStack(spacing: NftPreviewLayout.verificationSpacing) {
                    Text(preview.subtitle)
                        .textStyle(.body2)
                        .foregroundStyle(preview.subtitleColor)
                        .lineLimit(1)

                    if preview.isVerified {
                        Image(uiImage: .TKUIKit.Icons.Size16.verification)
                            .renderingMode(.template)
                            .foregroundStyle(Color(uiColor: .Icon.secondary))
                            .frame(
                                width: NftPreviewLayout.verificationIconSize,
                                height: NftPreviewLayout.verificationIconSize
                            )
                    }
                }
            }
            .padding(.horizontal, NftPreviewLayout.horizontalPadding)
            .padding(.top, NftPreviewLayout.verticalPadding)
            .padding(.bottom, NftPreviewLayout.verticalPadding)
        }
        .background(Color(uiColor: .Background.contentTint))
        .clipShape(
            RoundedRectangle(
                cornerRadius: NftPreviewLayout.cornerRadius,
                style: .continuous
            )
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Messages

extension TransactionCell {
    private enum MessageLayout {
        static let compactCornerRadius: CGFloat = 18
        static let regularCornerRadius: CGFloat = 12
        static let horizontalPadding: CGFloat = 12
        static let topPadding: CGFloat = 9
        static let bottomPadding: CGFloat = 10
    }

    private func message(_ content: TransactionCellContent.Message) -> some View {
        Text(content.text)
            .textStyle(.body2)
            .foregroundStyle(Color(uiColor: .Text.primary))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, MessageLayout.horizontalPadding)
            .padding(.top, MessageLayout.topPadding)
            .padding(.bottom, MessageLayout.bottomPadding)
            .background(
                RoundedRectangle(
                    cornerRadius: messageCornerRadius(for: content.style),
                    style: .continuous
                )
                .fill(Color(uiColor: .Background.contentTint))
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Layout.supplementaryTopInset)
    }

    private func messageCornerRadius(for style: TransactionCellContent.MessageStyle) -> CGFloat {
        switch style {
        case .compact:
            MessageLayout.compactCornerRadius
        case .regular:
            MessageLayout.regularCornerRadius
        }
    }
}

//
// public struct TransactionCell: View {
//    public struct Item: Identifiable {
//        public struct MessageBubble: Identifiable {
//            public enum Style {
//                case compact
//                case regular
//            }
//
//            public let id: String
//            public let text: String
//            public let style: Style
//
//            public init(
//                id: String,
//                text: String,
//                style: Style = .regular
//            ) {
//                self.id = id
//                self.text = text
//                self.style = style
//            }
//        }
//
//        public let id: String
//        public let icon: Icon
//        public let title: String
//        public let subtitle: String
//        public let subtitleStyle: SubtitleStyle
//        public let amountText: String
//        public let amountStyle: AmountStyle
//        public let secondaryAccessoryText: String
//        public let secondaryAccessoryTextStyle: TKTextStyle
//        public let secondaryAccessoryColor: Color
//        public let detailRow: DetailRow?
//        public let nftPreview: NFTPreview?
//        public let messages: [MessageBubble]
//        public let action: (() -> Void)?
//
//        public init(
//            id: String,
//            icon: Icon,
//            title: String,
//            subtitle: String,
//            subtitleStyle: SubtitleStyle = .primary,
//            amountText: String,
//            amountStyle: AmountStyle = .primary,
//            dateText: String,
//            secondaryAccessoryTextStyle: TKTextStyle = .body2,
//            secondaryAccessoryColor: Color = Color(uiColor: .Text.secondary),
//            detailRow: DetailRow? = nil,
//            nftPreview: NFTPreview? = nil,
//            messages: [MessageBubble] = [],
//            action: (() -> Void)? = nil
//        ) {
//            self.id = id
//            self.icon = icon
//            self.title = title
//            self.subtitle = subtitle
//            self.subtitleStyle = subtitleStyle
//            self.amountText = amountText
//            self.amountStyle = amountStyle
//            secondaryAccessoryText = dateText
//            self.secondaryAccessoryTextStyle = secondaryAccessoryTextStyle
//            self.secondaryAccessoryColor = secondaryAccessoryColor
//            self.detailRow = detailRow
//            self.nftPreview = nftPreview
//            self.messages = messages
//            self.action = action
//        }
//    }
//
//    private let items: [Item]
//
//    public init(items: [Item]) {
//        self.items = items
//    }
//
//    public var body: some View {
//        VStack(spacing: 0) {
//            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
//                rowContentView(
//                    item: item,
//                    showsSeparator: index < items.count - 1
//                )
//            }
//        }
//        .asCellsGroup()
//    }
//
//    private func rowContentView(
//        item: Item,
//        showsSeparator: Bool
//    ) -> some View {
//
//    }
// }
