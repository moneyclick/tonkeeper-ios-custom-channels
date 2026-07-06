import Foundation
import KeeperCore
import TKUIKit
import UIKit

struct MultichainSwapConfirmationInput {
    let sendAmount: String
    let receiveAmount: String
    let sendAsset: MultichainAsset
    let receiveAsset: MultichainAsset
}

@MainActor
final class MultichainSwapViewModel: ObservableObject {
    let amountFormatter: AmountFormatter
    private let onClose: () -> Void
    private let onContinue: () -> Void

    @Published var sendAmount: String = ""
    @Published var receiveAmount: String = ""

    @Published private(set) var sendAsset: MultichainAsset
    @Published private(set) var receiveAsset: MultichainAsset
    @Published private(set) var rateText: String = "1 TON ≈ 1.84 USDT"
    @Published private(set) var circularProgressRestartToken: Int = 0

    var onRequestPickSendToken: (() -> Void)?
    var onRequestPickReceiveToken: (() -> Void)?
    var onCircularProgressComplete: (() -> Void)?

    init(
        amountFormatter: AmountFormatter,
        sendAsset: MultichainAsset,
        receiveAsset: MultichainAsset,
        onClose: @escaping () -> Void = {},
        onContinue: @escaping () -> Void = {}
    ) {
        self.amountFormatter = amountFormatter
        self.sendAsset = sendAsset
        self.receiveAsset = receiveAsset
        self.onClose = onClose
        self.onContinue = onContinue
    }

    var isContinueEnabled: Bool {
        sendAmount != "0" && !sendAmount.isEmpty
    }

    func close() {
        onClose()
    }

    func continueSwap() {
        onContinue()
    }

    func notifyCircularProgressCompleted() {
        onCircularProgressComplete?()
        circularProgressRestartToken += 1
    }

    func swapTokens() {
        let sendAmt = sendAmount
        sendAmount = receiveAmount
        receiveAmount = sendAmt

        let previousSend = sendAsset
        sendAsset = receiveAsset
        receiveAsset = previousSend
    }

    func requestPickSendToken() {
        onRequestPickSendToken?()
    }

    func requestPickReceiveToken() {
        onRequestPickReceiveToken?()
    }

    func applySendAsset(_ asset: MultichainAsset) {
        sendAsset = asset
    }

    func applyReceiveAsset(_ asset: MultichainAsset) {
        receiveAsset = asset
    }

    func applyMaxSend() {
        sendAmount = amountFormatter.format(
            amount: sendAsset.balance,
            fractionDigits: sendAsset.asset.decimals,
            accessory: .none,
            style: .compact
        )
    }

    func toggleRateDisplayDirection() {}

    func makeConfirmationInput() -> MultichainSwapConfirmationInput {
        MultichainSwapConfirmationInput(
            sendAmount: sendAmount,
            receiveAmount: receiveAmount,
            sendAsset: sendAsset,
            receiveAsset: receiveAsset
        )
    }
}

extension MultichainAsset {
    var swapDisplaySymbol: String {
        asset.symbol.isEmpty ? asset.name : asset.symbol
    }

    var swapAvatarSource: AssetAvatarViewImageSource {
        .url(
            URL(string: asset.image),
            chainIcon: AssetIdResolver.chainIcon(for: asset.assetId)
        )
    }

    var swapNetworkTag: String? {
        AssetIdResolver.tag(for: asset.assetId)
    }

    func swapFormattedBalance(amountFormatter: AmountFormatter) -> String {
        amountFormatter.format(
            amount: balance,
            fractionDigits: asset.decimals,
            accessory: .tokenSymbol(swapDisplaySymbol),
            style: .compact
        )
    }

    func swapAmountLine(amount: String) -> String {
        [amount, swapDisplaySymbol]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " ")
    }
}
