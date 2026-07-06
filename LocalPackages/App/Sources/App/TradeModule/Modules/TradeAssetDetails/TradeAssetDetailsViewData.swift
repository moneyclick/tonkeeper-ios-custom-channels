import Foundation
import KeeperCore
import TKUIKit
import UIKit

struct TradeAssetDetailsHeaderSubtitleViewData {
    enum Action {
        case tokenizedAssetInfo(TokenizedAssetInfoKind)
        case unverifiedTokenInfo
    }

    let title: String
    let color: UIColor
    let action: Action
}

struct TradeAssetDetailsHeaderViewData {
    let title: String
    let imageSource: AssetAvatarViewImageSource
    let subtitle: TradeAssetDetailsHeaderSubtitleViewData?
    let earnText: String?
}

struct TradeAssetDetailsMetricViewData: Identifiable {
    let id: String
    let title: String
    let value: String
    let secondaryValue: String?
    let secondaryValuePositive: Bool
    let hint: String?

    var showsInfoIcon: Bool {
        hint != nil
    }
}

struct TradeAssetDetailsTradingActivityViewData {
    let volumeText: String
    let volumeChangeText: String?
    let volumeChangeColor: UIColor
    let volumeChangePositive: Bool
    let buyText: String
    let sellText: String
    let buyFraction: Double
}

struct TradeAssetDetailsBalanceSectionViewData {
    let symbol: String
    let iconImageSource: AssetAvatarViewImageSource
    let amountText: String
    let convertedAmountText: String?
    let chainTag: String?
}

struct TradeAssetDetailsLinkViewData: Identifiable {
    let id: String
    let title: String
    let kind: TradingAssetLinkKind
    let url: URL?
}

struct TradeAssetDetailsHistoryItemViewData: Identifiable {
    let id: String
    let icon: TKUIKit.TransactionCellContent.Icon
    let title: String
    let subtitle: String
    let amountText: String
    let amountStyle: TKUIKit.TransactionCellContent.AmountStyle
    let dateText: String
}

struct TradeAssetDetailsHistorySectionViewData {
    let items: [TradeAssetDetailsHistoryItemViewData]
}

struct TradeAssetDetailsScreenViewData {
    let id: String
    let title: String
    let imageURL: URL?
    let priceText: String
    let changeText: String?
    let changeAmountText: String?
    let changeColor: UIColor
    let earnText: String?
    let balance: TradeAssetDetailsBalanceSectionViewData?
    let aboutParagraph: String
    let overview: [TradeAssetDetailsMetricViewData]
    let tradingActivity: TradeAssetDetailsTradingActivityViewData?
    let history: TradeAssetDetailsHistorySectionViewData?
    let links: [TradeAssetDetailsLinkViewData]
    let primaryActionTitle: String
    let isSendAvailable: Bool
}
