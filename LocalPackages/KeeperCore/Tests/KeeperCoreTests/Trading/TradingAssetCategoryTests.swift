@testable import KeeperCore
import XCTest

final class TradingAssetCategoryTests: XCTestCase {
    func test_initWithAssetID_mapsSupportedKinds() {
        XCTAssertEqual(
            TradingAssetCategory(assetID: "ton/mainnet/coin"),
            .crypto
        )
        XCTAssertEqual(
            TradingAssetCategory(assetID: "ton/mainnet/jetton/0:123123"),
            .crypto
        )
        XCTAssertEqual(
            TradingAssetCategory(assetID: "ton/mainnet/stocks/0:abcdef"),
            .stocks
        )
        XCTAssertEqual(
            TradingAssetCategory(assetID: "ton/mainnet/etf/0:deadbeef"),
            .etfs
        )
    }

    func test_initWithAssetID_returnsNilForUnknownFormat() {
        XCTAssertNil(TradingAssetCategory(assetID: "rwa:TSLA"))
        XCTAssertNil(TradingAssetCategory(assetID: "ton/mainnet/unknown/0:deadbeef"))
    }
}
