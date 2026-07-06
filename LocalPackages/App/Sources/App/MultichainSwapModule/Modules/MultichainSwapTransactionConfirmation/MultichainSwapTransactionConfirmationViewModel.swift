import Foundation
import KeeperCore
import TKLocalize
import TKUIKit
import UIKit

struct MultichainSwapTransactionConfirmationDisplay {
    let sendLine: String
    let receiveLine: String
    let sendTokenAvatarSource: AssetAvatarViewImageSource
    let receiveTokenAvatarSource: AssetAvatarViewImageSource
    let rateLine: String
    let slippageLine: String
    let priceImpactTitle: String
    let priceImpactValue: String
    let networkFeeTitle: String
    let networkFeeValue: String
    let networkFeeMethod: String
    let networkFeeSubtitle: String
    let providerName: String

    static func make(
        from input: MultichainSwapConfirmationInput,
        rateLine: String
    ) -> MultichainSwapTransactionConfirmationDisplay {
        let sendLineRaw = input.sendAsset.swapAmountLine(amount: input.sendAmount)
        let receiveLineRaw = input.receiveAsset.swapAmountLine(amount: input.receiveAmount)
        let trimmedRate = rateLine.trimmingCharacters(in: .whitespacesAndNewlines)
        return MultichainSwapTransactionConfirmationDisplay(
            sendLine: sendLineRaw,
            receiveLine: receiveLineRaw,
            sendTokenAvatarSource: input.sendAsset.swapAvatarSource,
            receiveTokenAvatarSource: input.receiveAsset.swapAvatarSource,
            rateLine: trimmedRate.isEmpty ? "1 TON ≈ 0.00003912 BTC" : trimmedRate,
            slippageLine: "1%",
            priceImpactTitle: "Price impact",
            priceImpactValue: "≈ 0.94%",
            networkFeeTitle: "Network fee",
            networkFeeValue: "≈ $ 0.45",
            networkFeeMethod: "BTC",
            networkFeeSubtitle: "Speed: about 2 min",
            providerName: "Omniston"
        )
    }
}

@MainActor
final class MultichainSwapTransactionConfirmationViewModel: ObservableObject {
    @Published private(set) var display: MultichainSwapTransactionConfirmationDisplay

    private(set) var sendAsset: MultichainAsset
    private(set) var receiveAsset: MultichainAsset

    @Published private(set) var circularProgressRestartToken: Int = 0
    var onCircularProgressComplete: (() -> Void)?

    private let onBack: () -> Void
    private let onClose: () -> Void
    private let onSwipeConfirm: () -> Void
    private let onTapNetworkFeeMethod: () -> Void

    init(
        confirmationInput: MultichainSwapConfirmationInput,
        rateText: String,
        onBack: @escaping () -> Void = {},
        onClose: @escaping () -> Void = {},
        onSwipeConfirm: @escaping () -> Void = {},
        onTapNetworkFeeMethod: @escaping () -> Void = {}
    ) {
        self.display = MultichainSwapTransactionConfirmationDisplay.make(
            from: confirmationInput,
            rateLine: rateText
        )
        self.sendAsset = confirmationInput.sendAsset
        self.receiveAsset = confirmationInput.receiveAsset
        self.onBack = onBack
        self.onClose = onClose
        self.onSwipeConfirm = onSwipeConfirm
        self.onTapNetworkFeeMethod = onTapNetworkFeeMethod
    }

    var sliderConfirmTitle: NSAttributedString {
        let title = NSMutableAttributedString()
        title.append(
            TKLocales.Actions.Confirm.title.withTextStyle(
                .label2,
                color: .Text.secondary,
                alignment: .center
            )
        )
        title.append(
            ("\n" + TKLocales.Actions.Confirm.subtitle).withTextStyle(
                .body3,
                color: .Text.tertiary,
                alignment: .center
            )
        )
        return title
    }

    func back() {
        onBack()
    }

    func close() {
        onClose()
    }

    func confirmSwipe() {
        onSwipeConfirm()
    }

    func tapNetworkFeeMethod() {
        onTapNetworkFeeMethod()
    }

    func notifyCircularProgressCompleted() {
        onCircularProgressComplete?()
        circularProgressRestartToken += 1
    }

    func selectNetworkFeeMethod(_ method: String) {
        display = MultichainSwapTransactionConfirmationDisplay(
            sendLine: display.sendLine,
            receiveLine: display.receiveLine,
            sendTokenAvatarSource: display.sendTokenAvatarSource,
            receiveTokenAvatarSource: display.receiveTokenAvatarSource,
            rateLine: display.rateLine,
            slippageLine: display.slippageLine,
            priceImpactTitle: display.priceImpactTitle,
            priceImpactValue: display.priceImpactValue,
            networkFeeTitle: display.networkFeeTitle,
            networkFeeValue: display.networkFeeValue,
            networkFeeMethod: method,
            networkFeeSubtitle: display.networkFeeSubtitle,
            providerName: display.providerName
        )
    }
}
