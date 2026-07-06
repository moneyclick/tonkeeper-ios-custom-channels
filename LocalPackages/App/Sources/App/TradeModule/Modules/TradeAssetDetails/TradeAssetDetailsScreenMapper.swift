import BigInt
import Foundation
import KeeperCore
import TKLocalize
import TKUIKit
import UIKit

@MainActor
struct TradeAssetDetailsScreenMapper {
    let initialHeader: TradeAssetDetailsHeaderViewData

    private let assetID: String
    private let valueFormatter: TradeAssetDetailsValueFormatter
    private let displayFormatter: TradeAssetDetailsDisplayFormatter

    init(
        preview: TradeAssetDetailsViewModel.PreviewContext,
        amountFormatter: AmountFormatter,
        signedAmountFormatter: AmountFormatter,
        currencyProvider: @escaping () -> Currency
    ) {
        self.assetID = preview.assetID
        let valueFormatter = TradeAssetDetailsValueFormatter(
            amountFormatter: amountFormatter,
            signedAmountFormatter: signedAmountFormatter,
            currencyProvider: currencyProvider
        )
        self.valueFormatter = valueFormatter
        self.displayFormatter = TradeAssetDetailsDisplayFormatter(
            amountFormatter: amountFormatter,
            valueFormatter: valueFormatter,
            currencyProvider: currencyProvider
        )
        self.initialHeader = TradeAssetDetailsHeaderViewData(
            title: preview.title ?? "",
            imageSource: AssetIdResolver.imageSource(for: preview.assetID, imageUrl: preview.imageURL),
            subtitle: TradeAssetDetailsHeaderSubtitleViewData(
                assetCategory: preview.assetCategory,
                isUnverified: preview.isUnverified
            ),
            earnText: nil
        )
    }

    func map(
        details: TradingAssetDetails?,
        marketData: TradeAssetDetailsMarketData?,
        balance: TradeAssetDetailsBalanceSnapshot?,
        history: TradeAssetDetailsHistoryPreview?
    ) -> (header: TradeAssetDetailsHeaderViewData, screen: TradeAssetDetailsScreenViewData?) {
        guard let details else {
            return (initialHeader, nil)
        }

        let assetInfo = details.assetInfo
        let formattedVolumeChangeText = details.tradingActivity
            .flatMap(\.volumeChangeText)
            .flatMap(displayFormatter.formatTradingChange)
        let earnText = valueFormatter.earnApyButtonFormatter(assetInfo.earnAPY)

        let displayTitle: String
        if case .ton = assetInfo.typedAssetId {
            displayTitle = TonInfo.name
        } else {
            displayTitle = assetInfo.title
        }

        let header = TradeAssetDetailsHeaderViewData(
            title: displayTitle,
            imageSource: AssetIdResolver.imageSource(for: assetInfo.assetId, imageUrl: assetInfo.imageURL),
            subtitle: TradeAssetDetailsHeaderSubtitleViewData(assetInfo: assetInfo),
            earnText: earnText
        )

        let screen = TradeAssetDetailsScreenViewData(
            id: details.id,
            title: displayTitle,
            imageURL: assetInfo.imageURL,
            priceText: marketData?.priceText ?? valueFormatter.formatPrice(assetInfo.price),
            changeText: marketData?.changeText ?? valueFormatter.formatChange(assetInfo.changePercent),
            changeAmountText: marketData?.changeAmountText ?? valueFormatter.formatSignedPrice(assetInfo.changeAmount),
            changeColor: marketData?.changeColor
                ?? ((assetInfo.changePercent ?? 0) < 0 ? .Accent.red : .Accent.green),
            earnText: earnText,
            balance: balanceSection(balance),
            aboutParagraph: details.aboutParagraph,
            overview: details.overview.map {
                TradeAssetDetailsMetricViewData(
                    id: $0.id,
                    title: $0.title,
                    value: displayFormatter.formatOverviewValue($0, assetDecimals: assetInfo.decimals),
                    secondaryValue: displayFormatter.formatOverviewSecondaryValue($0),
                    secondaryValuePositive: $0.secondaryValueIsPositive,
                    hint: $0.hint
                )
            },
            tradingActivity: details.tradingActivity.map { tradingActivity in
                TradeAssetDetailsTradingActivityViewData(
                    volumeText: displayFormatter.formatTradingAmount(tradingActivity.volumeText),
                    volumeChangeText: formattedVolumeChangeText,
                    volumeChangeColor: displayFormatter.isPositive(formattedVolumeChangeText) ? .Accent.green : .Accent.red,
                    volumeChangePositive: displayFormatter.isPositive(formattedVolumeChangeText),
                    buyText: displayFormatter.formatTradingSide(
                        title: TKLocales.BuySellList.buy,
                        value: tradingActivity.buyText
                    ),
                    sellText: displayFormatter.formatTradingSide(
                        title: TKLocales.BuySellList.sell,
                        value: tradingActivity.sellText
                    ),
                    buyFraction: tradingActivity.buyFraction
                )
            },
            history: historySection(history),
            links: details.links.map {
                TradeAssetDetailsLinkViewData(
                    id: $0.id,
                    title: $0.title,
                    kind: $0.kind,
                    url: $0.url
                )
            },
            primaryActionTitle: details.primaryActionTitle,
            isSendAvailable: isSendAvailable(balance)
        )

        return (header, screen)
    }
}

private extension TradeAssetDetailsScreenMapper {
    func balanceSection(
        _ snapshot: TradeAssetDetailsBalanceSnapshot?
    ) -> TradeAssetDetailsBalanceSectionViewData? {
        guard let snapshot, !snapshot.amount.isZero else {
            return nil
        }

        return TradeAssetDetailsBalanceSectionViewData(
            symbol: snapshot.symbol,
            iconImageSource: AssetIdResolver.imageSource(for: assetID, imageUrl: snapshot.imageURL),
            amountText: displayFormatter.formatBalanceAmount(
                amount: snapshot.amount,
                fractionDigits: snapshot.fractionDigits,
                symbol: snapshot.symbol
            ),
            convertedAmountText: displayFormatter.formatBalanceConverted(snapshot.convertedAmount),
            chainTag: snapshot.tagText ?? AssetIdResolver.tag(for: assetID)
        )
    }

    func historySection(
        _ preview: TradeAssetDetailsHistoryPreview?
    ) -> TradeAssetDetailsHistorySectionViewData? {
        guard let preview, !preview.items.isEmpty else {
            return nil
        }

        return TradeAssetDetailsHistorySectionViewData(
            items: preview.items.map {
                TradeAssetDetailsHistoryItemViewData(
                    id: $0.id,
                    icon: $0.icon,
                    title: $0.title,
                    subtitle: $0.subtitle,
                    amountText: $0.amountText,
                    amountStyle: $0.amountStyle,
                    dateText: $0.dateText
                )
            }
        )
    }

    func isSendAvailable(_ snapshot: TradeAssetDetailsBalanceSnapshot?) -> Bool {
        guard let snapshot else {
            return false
        }

        return !snapshot.amount.isZero
    }
}

private extension TradeAssetDetailsHeaderSubtitleViewData {
    init?(
        assetCategory: TradingAssetCategory?,
        isUnverified: Bool?
    ) {
        if isUnverified == true {
            self.init(
                title: TKLocales.Token.unverified,
                color: .Accent.orange,
                action: .unverifiedTokenInfo
            )
            return
        }

        guard let kind = assetCategory?.tokenizedAssetInfoKind else {
            return nil
        }

        self.init(
            title: kind.badgeTitle,
            color: .Accent.blue,
            action: .tokenizedAssetInfo(kind)
        )
    }

    init?(assetInfo: TradingAssetInfo) {
        self.init(
            assetCategory: assetInfo.category,
            isUnverified: assetInfo.isUnverified
        )
    }
}

private extension TradingAssetCategory {
    var tokenizedAssetInfoKind: TokenizedAssetInfoKind? {
        switch self {
        case .stocks:
            return .stock
        case .etfs:
            return .etf
        case .all, .crypto:
            return nil
        }
    }
}
