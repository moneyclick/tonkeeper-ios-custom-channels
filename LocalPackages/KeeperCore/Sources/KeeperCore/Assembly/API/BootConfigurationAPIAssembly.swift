import Foundation

final class BootConfigurationAPIAssembly {
    private let appInfoProvider: AppInfoProvider

    init(appInfoProvider: AppInfoProvider) {
        self.appInfoProvider = appInfoProvider
    }

    var api: BootConfigurationAPI {
        BootConfigurationAPIImplementation(
            urlSession: .shared,
            bootHost: apiV1BootURL,
            blockHost: apiV1BlockURL,
            appInfoProvider: appInfoProvider
        )
    }

    var apiV1BootURL: URL {
        URL(string: "https://boot.tonkeeper.com")!
    }

    var apiV1BlockURL: URL {
        URL(string: "https://block.tonkeeper.com")!
    }
}
