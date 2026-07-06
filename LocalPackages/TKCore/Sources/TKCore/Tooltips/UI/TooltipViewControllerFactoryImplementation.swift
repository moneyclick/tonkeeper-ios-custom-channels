import SwiftUI
import TKLocalize
import TKUIKit

final class TooltipViewControllerFactoryImplementation {}

extension TooltipViewControllerFactoryImplementation: TooltipViewControllerFactory {
    func makeHintViewController(
        id: TooltipID,
        direction: HintPosition.Direction?,
        maximumWidth: CGFloat
    ) -> UIViewController {
        let rootView: AnyView
        switch id {
        case .walletBalanceWithdraw:
            rootView = AnyView(
                TKTooltipView(
                    configuration: TKTooltipView.Configuration(
                        title: TKLocales.WalletButtons.sendFromHere,
                        badgeTitle: TKLocales.Common.new
                    ),
                    position: direction
                )
            )
        case .newHistoryEntryPoint:
            rootView = AnyView(
                TKTooltipView(
                    configuration: TKTooltipView.Configuration(
                        title: TKLocales.Tabs.History.hint,
                        badgeTitle: TKLocales.Common.new
                    ),
                    position: direction
                )
            )
        case .tradeTab:
            rootView = AnyView(
                TKTooltipView(
                    configuration: TKTooltipView.Configuration(
                        title: TKLocales.Tabs.Trade.hint,
                        badgeTitle: TKLocales.Common.new
                    ),
                    position: direction
                )
            )
        }
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.backgroundColor = .clear
        let size = hostingController.sizeThatFits(
            in: CGSize(
                width: maximumWidth,
                height: CGFloat.greatestFiniteMagnitude
            )
        )
        hostingController.preferredContentSize = CGSize(
            width: min(maximumWidth, ceil(size.width)),
            height: ceil(size.height)
        )
        return hostingController
    }
}
