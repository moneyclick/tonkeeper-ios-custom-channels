import Foundation
import KeeperCore
import TKCore

typealias SupportPopupModule = MVVMModule<SupportPopupViewController, SupportPopupModuleOutput, Void>

@MainActor
enum SupportPopupAssembly {
    static func module(
        directSupportURL: URL?,
        supportEmailURL: URL?
    ) -> SupportPopupModule {
        let viewModel = SupportPopupViewModelImplementation(
            directSupportURL: directSupportURL,
            supportEmailURL: supportEmailURL
        )
        let viewController = SupportPopupViewController(viewModel: viewModel)
        return MVVMModule(
            view: viewController,
            output: viewModel,
            input: ()
        )
    }
}
