import Foundation
@testable import KeeperCore
import XCTest

final class CurrencyTests: XCTestCase {
    func testRawValueInitializerMapsLegacyTONToGRAM() {
        XCTAssertEqual(Currency(rawValue: "TON"), .GRAM)
        XCTAssertEqual(Currency(rawValue: "GRAM"), .GRAM)
        XCTAssertNil(Currency(rawValue: "UNKNOWN"))
    }

    func testLegacyTONDecodesAsGRAMAndEncodesAsGRAM() throws {
        let currency = try JSONDecoder().decode(Currency.self, from: Data(#""TON""#.utf8))

        XCTAssertEqual(currency, .GRAM)

        let data = try JSONEncoder().encode(currency)
        XCTAssertEqual(String(data: data, encoding: .utf8), #""GRAM""#)
    }
}
