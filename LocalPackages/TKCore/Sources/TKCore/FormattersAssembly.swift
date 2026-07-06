import Foundation
import KeeperCore

public struct FormattersAssembly {
    public func chartFormatter(
        dateFormatter: DateFormatter,
        amountFormatter: AmountFormatter,
        signedAmountFormatter: AmountFormatter
    ) -> ChartFormatter {
        ChartFormatter(
            dateFormatter: dateFormatter,
            amountFormatter: amountFormatter,
            signedAmountFormatter: signedAmountFormatter
        )
    }
}
