import Foundation
import TKUIKit
import UIKit

public protocol TooltipsService: AnyObject {
    @MainActor
    func showTooltipIfNeeded(
        id: TooltipID,
        sourceView: UIView,
        targetActionViews: [UIView],
        configuration: HintConfiguration
    )

    @MainActor
    func didPerformTooltipTargetAction(id: TooltipID)
}
