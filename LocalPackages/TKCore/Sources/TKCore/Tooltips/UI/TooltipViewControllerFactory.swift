import TKUIKit
import UIKit

public protocol TooltipViewControllerFactory {
    func makeHintViewController(
        id: TooltipID,
        direction: HintPosition.Direction?,
        maximumWidth: CGFloat
    ) -> UIViewController
}
