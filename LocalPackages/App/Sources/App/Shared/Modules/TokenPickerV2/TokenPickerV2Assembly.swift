import Foundation
import KeeperCore
import TKCore

struct TokenPickerV2Assembly {
    private init() {}
    @MainActor
    static func module(
        wallet: Wallet,
        model: any TokenPickerV2Model,
        keeperCoreMainAssembly: KeeperCore.MainAssembly
    ) -> MVVMModule<TokenPickerV2ViewController, TokenPickerV2ModuleOutput, Void> {
        let viewModel = TokenPickerV2ViewModelImplementation(
            tokenPickerModel: model,
            amountFormatter: keeperCoreMainAssembly.formattersAssembly.amountFormatter,
            currencyStore: keeperCoreMainAssembly.storesAssembly.currencyStore
        )
        let viewController = TokenPickerV2ViewController(viewModel: viewModel)
        return .init(view: viewController, output: viewModel, input: ())
    }
}
