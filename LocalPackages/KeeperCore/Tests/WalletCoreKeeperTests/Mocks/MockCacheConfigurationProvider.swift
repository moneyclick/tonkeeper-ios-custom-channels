//
//  MockCacheConfigurationProvider.swift
//
//
//  Created by Grigory on 21.6.23..
//

import Foundation
@testable import WalletCoreKeeper

final class MockCacheConfigurationProvider: CacheConfigurationProvider {
    var configuration: BootConfiguration {
        get throws {
            if let _configuration = _configuration {
                return _configuration
            }
            throw NSError(domain: "", code: 0)
        }
    }

    var _configuration: BootConfiguration?

    func saveConfiguration(_ configuration: WalletCoreKeeper.BootConfiguration) throws {
        self._configuration = configuration
    }
}
