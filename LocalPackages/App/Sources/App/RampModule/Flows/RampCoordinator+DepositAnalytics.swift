import Foundation
import KeeperCore
import TKCore

extension RampCoordinator {
    func fireDepositStarted(availableOptions: Set<String>) {
        guard flow == .deposit else { return }
        coreAssembly.analyticsProvider.log(
            flowContext.makeDepositStarted(availableOptions: availableOptions)
        )
    }

    func fireDepositOptionClick(option: DepositAddFundsOption) {
        guard flow == .deposit else { return }
        flowContext.addFundsOption = option
        coreAssembly.analyticsProvider.log(
            flowContext.makeDepositOptionClick(option: option)
        )
    }

    func fireDepositViewP2pAlert() {
        guard flow == .deposit, let event = flowContext.makeDepositViewP2pAlert() else { return }
        coreAssembly.analyticsProvider.log(event)
    }

    func fireDepositContinueToP2pMarket() {
        guard flow == .deposit, let event = flowContext.makeDepositContinueToP2pMarket() else { return }
        coreAssembly.analyticsProvider.log(event)
        depositPendingTracker.markPending(wallet: wallet)
    }

    func fireDepositViewBuyTonWithCrypto(availableOptions: Set<String>) {
        guard flow == .deposit, let event = flowContext.makeDepositViewBuyTonWithCrypto(availableOptions: availableOptions) else { return }
        coreAssembly.analyticsProvider.log(event)
        depositPendingTracker.markPending(wallet: wallet)
    }

    func fireDepositViewSendAsset(sellAsset: String, buyAsset: String) {
        guard flow == .deposit else { return }
        flowContext.sellAsset = sellAsset
        flowContext.buyAsset = buyAsset
        guard let event = flowContext.makeDepositViewSendAsset() else { return }
        coreAssembly.analyticsProvider.log(event)
        depositPendingTracker.markPending(wallet: wallet)
    }

    func fireDepositViewQrCode() {
        guard flow == .deposit, let event = flowContext.makeDepositViewQrCode() else { return }
        coreAssembly.analyticsProvider.log(event)
        depositPendingTracker.markPending(wallet: wallet)
    }

    func fireDepositViewFiatChooseAsset(availableOptions: Set<String>) {
        guard flow == .deposit, let event = flowContext.makeDepositViewFiatChooseAsset(availableOptions: availableOptions) else { return }
        coreAssembly.analyticsProvider.log(event)
    }

    func fireDepositClickFiatAsset(buyAsset: String) {
        guard flow == .deposit else { return }
        flowContext.buyAsset = buyAsset
        guard let event = flowContext.makeDepositClickFiatAsset() else { return }
        coreAssembly.analyticsProvider.log(event)
    }

    func fireDepositViewFiatPaymentMethod(sellAsset: String, availableOptions: Set<String>) {
        guard flow == .deposit else { return }
        flowContext.sellAsset = sellAsset
        guard let event = flowContext.makeDepositViewFiatPaymentMethod(availableOptions: availableOptions) else { return }
        coreAssembly.analyticsProvider.log(event)
        depositPendingTracker.markPending(wallet: wallet)
    }

    func fireDepositClickFiatPaymentMethod(paymentMethod: String) {
        guard flow == .deposit else { return }
        flowContext.paymentMethod = paymentMethod
        guard let event = flowContext.makeDepositClickFiatPaymentMethod() else { return }
        coreAssembly.analyticsProvider.log(event)
    }

    func fireDepositViewRampInsertAmount(providerName: String) {
        guard flow == .deposit else { return }
        flowContext.providerName = providerName
        guard let event = flowContext.makeDepositViewRampInsertAmount() else { return }
        coreAssembly.analyticsProvider.log(event)
    }

    func fireDepositClickRampInsertAmountContinue(amount: Float, providerName: String) {
        guard flow == .deposit else { return }
        flowContext.amount = amount
        flowContext.providerName = providerName
        guard let event = flowContext.makeDepositClickRampInsertAmountContinue() else { return }
        coreAssembly.analyticsProvider.log(event)
    }

    func fireDepositViewRampAlert() {
        guard flow == .deposit, let event = flowContext.makeDepositViewRampAlert() else { return }
        coreAssembly.analyticsProvider.log(event)
    }

    func fireDepositContinueToRampProvider(txId: String) {
        guard flow == .deposit else { return }
        flowContext.txId = txId
        guard let event = flowContext.makeDepositContinueToRampProvider() else { return }
        coreAssembly.analyticsProvider.log(event)
        depositPendingTracker.markPending(wallet: wallet)
    }

    func fireDepositViewChooseStablecoin(availableOptions: Set<String>) {
        guard flow == .deposit, let event = flowContext.makeDepositViewChooseStablecoin(availableOptions: availableOptions) else { return }
        coreAssembly.analyticsProvider.log(event)
    }

    func fireDepositClickStablecoin(buyAsset: String) {
        guard flow == .deposit else { return }
        flowContext.buyAsset = buyAsset
        guard let event = flowContext.makeDepositClickStablecoin() else { return }
        coreAssembly.analyticsProvider.log(event)
    }

    func fireDepositViewStablecoinPaymentMethod(availableOptions: Set<String>) {
        guard flow == .deposit, let event = flowContext.makeDepositViewStablecoinPaymentMethod(availableOptions: availableOptions) else { return }
        coreAssembly.analyticsProvider.log(event)
        depositPendingTracker.markPending(wallet: wallet)
    }

    func fireDepositClickStablecoinPaymentMethod(stablecoinSymbol: String) {
        guard flow == .deposit else { return }
        flowContext.stablecoinSymbol = stablecoinSymbol
        guard let event = flowContext.makeDepositClickStablecoinPaymentMethod() else { return }
        coreAssembly.analyticsProvider.log(event)
    }

    func fireDepositViewChooseNetwork(availableOptions: Set<String>) {
        guard flow == .deposit, let event = flowContext.makeDepositViewChooseNetwork(availableOptions: availableOptions) else { return }
        coreAssembly.analyticsProvider.log(event)
    }

    func fireDepositClickNetwork(sellAsset: String) {
        guard flow == .deposit else { return }
        flowContext.sellAsset = sellAsset
        guard let event = flowContext.makeDepositClickNetwork() else { return }
        coreAssembly.analyticsProvider.log(event)
    }
}

// MARK: - Slug helpers

extension OnRampLayoutItemType {
    var depositAddFundsOption: DepositAddFundsOption? {
        switch self {
        case .fiat: .buyWithFiat
        case .crypto: .buyTonWithCrypto
        case .stablecoin: .buyWithStablecoins
        }
    }

    var availableOptionsSlug: String? {
        depositAddFundsOption?.rawValue
    }
}

extension OnRampLayout {
    var addFundsAvailableOptions: Set<String> {
        var options: Set<String> = [DepositAddFundsOption.receiveTokens.rawValue]
        for item in items {
            if let slug = item.type.availableOptionsSlug {
                options.insert(slug)
            }
        }
        return options
    }
}
