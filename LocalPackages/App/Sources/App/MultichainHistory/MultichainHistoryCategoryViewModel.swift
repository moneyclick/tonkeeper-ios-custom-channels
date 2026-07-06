import Foundation
import KeeperCore

@MainActor
final class MultichainHistoryCategoryViewModel {
    private let walletId: String
    private let category: MultichainHistoryCategory
    private let multichainService: MultichainService
    private let amountFormatter: AmountFormatter
    private let dateFormatter: DateFormatter
    private let currentDateProvider: () -> Date
    private let onAddFunds: () -> Void

    private var cachedQueryViewModel: MultichainHistoryQueryViewModel?

    init(
        walletId: String,
        category: MultichainHistoryCategory,
        multichainService: MultichainService,
        amountFormatter: AmountFormatter,
        dateFormatter: DateFormatter,
        currentDateProvider: @escaping () -> Date,
        onAddFunds: @escaping () -> Void
    ) {
        self.walletId = walletId
        self.category = category
        self.multichainService = multichainService
        self.amountFormatter = amountFormatter
        self.dateFormatter = dateFormatter
        self.currentDateProvider = currentDateProvider
        self.onAddFunds = onAddFunds
    }

    func queryViewModel() -> MultichainHistoryQueryViewModel {
        if let cachedQueryViewModel {
            return cachedQueryViewModel
        }

        let queryViewModel = MultichainHistoryQueryViewModel(
            walletId: walletId,
            category: category,
            multichainService: multichainService,
            amountFormatter: amountFormatter,
            dateFormatter: dateFormatter,
            currentDateProvider: currentDateProvider,
            onAddFunds: onAddFunds
        )
        cachedQueryViewModel = queryViewModel
        return queryViewModel
    }

    func disappeared() {
        cachedQueryViewModel?.disappeared()
    }
}
