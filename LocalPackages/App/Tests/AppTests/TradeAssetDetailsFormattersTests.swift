@testable import App
import Foundation
import KeeperCore
import XCTest

final class TradeAssetDetailsFormattersTests: XCTestCase {
    func test_formatTradingAmount_truncatesNearNextAbbreviationThreshold() {
        let formatter = makeDisplayFormatter()

        XCTAssertEqual(formatter.formatTradingAmount("999995"), "$999.99K")
        XCTAssertEqual(formatter.formatTradingAmount("999999"), "$999.99K")
        XCTAssertEqual(formatter.formatTradingAmount("999999000"), "$999.99M")
    }

    func test_formatTradingAmount_doesNotGroupAbbreviatedValues() {
        let formatter = makeDisplayFormatter()

        XCTAssertEqual(formatter.formatTradingAmount("999994"), "$999.99K")
        XCTAssertEqual(formatter.formatTradingAmount("1234567"), "$1.23M")
    }
}

private extension TradeAssetDetailsFormattersTests {
    func makeDisplayFormatter() -> TradeAssetDetailsDisplayFormatter {
        let amountFormatter = AmountFormatter(
            configuration: makeAmountFormatterConfiguration(groupDigits: true)
        )
        var signedConfiguration = makeAmountFormatterConfiguration(groupDigits: true)
        signedConfiguration.signPolicy = .always
        let signedAmountFormatter = AmountFormatter(configuration: signedConfiguration)
        let valueFormatter = TradeAssetDetailsValueFormatter(
            amountFormatter: amountFormatter,
            signedAmountFormatter: signedAmountFormatter,
            currencyProvider: { .USD }
        )

        return TradeAssetDetailsDisplayFormatter(
            amountFormatter: amountFormatter,
            valueFormatter: valueFormatter,
            currencyProvider: { .USD }
        )
    }

    func makeAmountFormatterConfiguration(groupDigits: Bool) -> AmountFormatter.Configuration {
        var configuration = AmountFormatter.Configuration()
        configuration.locale = Locale(identifier: "en_US_POSIX")
        configuration.groupDigits = groupDigits
        configuration.space = "\u{2009}"
        return configuration
    }
}
