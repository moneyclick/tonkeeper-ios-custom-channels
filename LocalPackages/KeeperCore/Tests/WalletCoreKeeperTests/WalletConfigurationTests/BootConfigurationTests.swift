import TonAPI
@testable import WalletCoreKeeper
import XCTest

final class BootConfigurationTests: XCTestCase {
    func testBootConfigurationModelDecoding() throws {
        let configurationResponseString = """
        {
          "tonapiV2Endpoint": "https://tonapi.io",
          "tonapiTestnetHost": "https://testnet.tonapi.io",
          "tonApiV2Key": "AF77F5JNEUSNXPQAAAAMDXXG7RBQ3IRP6PC2HTHL4KYRWMZYOUQGDEKYFDKBETZ6FDVZJBI",
        }
        """

        let decoder = JSONDecoder()
        XCTAssertNoThrow(try decoder.decode(BootConfiguration.self, from: XCTUnwrap(configurationResponseString.data(using: .utf8))))
    }
}
