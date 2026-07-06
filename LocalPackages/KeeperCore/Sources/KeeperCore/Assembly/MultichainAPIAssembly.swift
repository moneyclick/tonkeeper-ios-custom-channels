import Foundation

final class MultichainAPIAssembly {
    private var _multichainClientAPI: MultichainClientAPI?

    let appInfoProvider: AppInfoProvider
    let apiAssembly: APIAssembly

    init(
        appInfoProvider: AppInfoProvider,
        apiAssembly: APIAssembly
    ) {
        self.appInfoProvider = appInfoProvider
        self.apiAssembly = apiAssembly
    }

    func multichainAPI() -> MultichainClientAPI {
        if let api = _multichainClientAPI {
            return api
        }
        let api = MultichainClientAPIImplementation(
            multichainAPIClient: apiAssembly.multichainAPIClient(userAgent: appInfoProvider.userAgent)
        )
        _multichainClientAPI = api
        return api
    }
}
