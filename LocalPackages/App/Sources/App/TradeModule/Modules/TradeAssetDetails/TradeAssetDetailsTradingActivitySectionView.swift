import SwiftUI
import TKLocalize
import TKUIKit

struct TradeAssetDetailsTradingActivitySectionView: View {
    let tradingActivity: TradeAssetDetailsTradingActivityViewData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ListTitleView(
                config: .text(
                    TKLocales.Trade.AssetDetails.Sections.tradingActivity
                )
            )

            TradingActivityView(
                leftTitle: TKLocales.Trade.AssetDetails.TradingActivity.volumeTitle,
                rightTitle: tradingActivity.volumeText,
                delta: tradingActivity.volumeChangeText.map { volumeChangeText in
                    TradingActivityView.Delta(
                        title: volumeChangeText,
                        isPositive: tradingActivity.volumeChangePositive
                    )
                },
                sellText: tradingActivity.sellText,
                buyText: tradingActivity.buyText,
                buyFraction: tradingActivity.buyFraction,
                hintText: TKLocales.Trade.AssetDetails.TradingActivity.volumeHint
            )

            Text(TKLocales.Trade.AssetDetails.TradingActivity.attribution)
                .textStyle(.body3)
                .foregroundStyle(Color(uiColor: .Text.tertiary))
                .padding(.top, Layout.attributionTopPadding)
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }
}

private extension TradeAssetDetailsTradingActivitySectionView {
    enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let attributionTopPadding: CGFloat = 13
    }
}
