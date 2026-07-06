import Foundation
import KeeperCore
import TKLocalize
import TKUIKit
import UIKit

@MainActor
final class MultichainHistoryViewModelImplementation: ObservableObject {
    private static let visibleTypeFilters: [MultichainHistoryTypeFilter] = [
        .all,
        .send,
        .receive,
    ]

    @Published private(set) var chainTabs = [MultichainHistoryChainTab]()
    @Published private(set) var selectedChainFilter: MultichainHistoryChainFilter = .all
    @Published private(set) var selectedTypeFilter: MultichainHistoryTypeFilter = .all
    @Published private(set) var currentQueryViewModel: MultichainHistoryQueryViewModel?

    var typeFilterItems: [MultichainHistoryTypeFilterItem] {
        Self.visibleTypeFilters.map { filter in
            MultichainHistoryTypeFilterItem(
                id: filter,
                title: filter.title,
                isSelected: filter == selectedTypeFilter
            )
        }
    }

    var selectedTypeFilterTitle: String {
        switch selectedTypeFilter {
        case .all:
            return TKLocales.History.Tab.allTypes
        case .send, .receive, .swap:
            return selectedTypeFilter.title
        }
    }

    func isTypeFilterActionBarVisible(for queryViewModel: MultichainHistoryQueryViewModel) -> Bool {
        selectedTypeFilter != .all || queryViewModel.hasActivityItems
    }

    private let wallet: Wallet
    private let multichainService: MultichainService
    private let amountFormatter: AmountFormatter
    private let dateFormatter: DateFormatter
    private let currentDateProvider: () -> Date
    private let chainImageProvider: (MultichainChain) -> UIImage?
    private let chainFiltersProvider: (Wallet) -> [MultichainHistoryChainFilter]
    private let onAddFunds: () -> Void

    private var categoryViewModels = [MultichainHistoryCategory: MultichainHistoryCategoryViewModel]()
    private var hasLoaded = false

    init(
        wallet: Wallet,
        multichainService: MultichainService,
        amountFormatter: AmountFormatter,
        dateFormatter: DateFormatter,
        currentDateProvider: @escaping () -> Date = Date.init,
        chainImageProvider: @escaping (MultichainChain) -> UIImage? = { $0.addressConfiguration.icon },
        chainFiltersProvider: @escaping (Wallet) -> [MultichainHistoryChainFilter] = { $0.multichainHistoryChainFilters },
        onAddFunds: @escaping () -> Void = {}
    ) {
        self.wallet = wallet
        self.multichainService = multichainService
        self.amountFormatter = amountFormatter
        self.dateFormatter = dateFormatter
        self.currentDateProvider = currentDateProvider
        self.chainImageProvider = chainImageProvider
        self.chainFiltersProvider = chainFiltersProvider
        self.onAddFunds = onAddFunds
    }

    func viewDidLoad() {
        guard !hasLoaded else {
            return
        }

        let filters = chainFiltersProvider(wallet)
        chainTabs = makeChainTabs(filters: filters)
        if !filters.contains(selectedChainFilter) {
            selectedChainFilter = .all
        }

        hasLoaded = true
        activateCurrentCategory()
    }

    func selectChainFilter(_ filter: MultichainHistoryChainFilter) {
        guard selectedChainFilter != filter else {
            return
        }

        selectedChainFilter = filter
        guard hasLoaded else {
            return
        }
        activateCurrentCategory()
    }

    func selectTypeFilter(_ filter: MultichainHistoryTypeFilter) {
        guard selectedTypeFilter != filter else {
            return
        }

        selectedTypeFilter = filter
        guard hasLoaded else {
            return
        }
        activateCurrentCategory()
    }

    func refresh() async {
        await currentQueryViewModel?.refresh()
    }

    func disappeared() {
        categoryViewModels.values.forEach { $0.disappeared() }
    }

    func contentViewModel(for category: MultichainHistoryCategory) -> MultichainHistoryQueryViewModel {
        categoryViewModel(for: category).queryViewModel()
    }
}

private extension MultichainHistoryViewModelImplementation {
    var currentCategory: MultichainHistoryCategory {
        MultichainHistoryCategory(
            chainFilter: selectedChainFilter,
            typeFilter: selectedTypeFilter
        )
    }

    func activateCurrentCategory() {
        let queryViewModel = contentViewModel(for: currentCategory)
        if currentQueryViewModel !== queryViewModel {
            currentQueryViewModel = queryViewModel
        }
        queryViewModel.appeared()
    }

    func categoryViewModel(for category: MultichainHistoryCategory) -> MultichainHistoryCategoryViewModel {
        if let categoryViewModel = categoryViewModels[category] {
            return categoryViewModel
        }

        let categoryViewModel = MultichainHistoryCategoryViewModel(
            walletId: wallet.id,
            category: category,
            multichainService: multichainService,
            amountFormatter: amountFormatter,
            dateFormatter: dateFormatter,
            currentDateProvider: currentDateProvider,
            onAddFunds: onAddFunds
        )
        categoryViewModels[category] = categoryViewModel
        return categoryViewModel
    }

    func makeChainTabs(filters: [MultichainHistoryChainFilter]) -> [MultichainHistoryChainTab] {
        filters.map { filter in
            switch filter {
            case .all:
                return MultichainHistoryChainTab(
                    id: .all,
                    title: TKLocales.History.Tab.all,
                    image: nil,
                    isSelectable: true
                )
            case let .chain(chain):
                return MultichainHistoryChainTab(
                    id: .chain(chain),
                    title: chain.multichainHistoryTitle,
                    image: chainImageProvider(chain),
                    isSelectable: true
                )
            }
        }
    }
}

private extension MultichainChain {
    var multichainHistoryTitle: String {
        switch self {
        case .ton:
            return TKLocales.Receive.Multichain.Networks.Ton.title
        case .eth:
            return TKLocales.Receive.Multichain.Networks.Ethereum.title
        case .btc:
            return TKLocales.Receive.Multichain.Networks.Bitcoin.title
        case .base:
            return TKLocales.Receive.Multichain.Networks.Base.title
        case .bsc:
            return TKLocales.Receive.Multichain.Networks.Smartchain.title
        case .arb:
            return TKLocales.Receive.Multichain.Networks.Arbitrum.title
        case .tron:
            return TKLocales.Receive.Multichain.Networks.Tron.title
        case .sol:
            return TKLocales.Receive.Multichain.Networks.Solana.title
        }
    }
}
