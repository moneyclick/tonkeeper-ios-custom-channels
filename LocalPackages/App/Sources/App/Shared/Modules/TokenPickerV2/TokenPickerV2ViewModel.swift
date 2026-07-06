import Foundation
import KeeperCore
import TKLocalize
import TKUIKit
import UIKit

@MainActor
protocol TokenPickerV2ModuleOutput: AnyObject {
    var didFinish: (() -> Void)? { get set }
    var didSelectAsset: ((MultichainAsset) -> Void)? { get set }
}

@MainActor
final class TokenPickerV2ViewModelImplementation: ObservableObject, TokenPickerV2ModuleOutput {
    private enum Constants {
        static let searchDebounceNanoseconds: UInt64 = 300_000_000
    }

    var didFinish: (() -> Void)?
    var didSelectAsset: ((MultichainAsset) -> Void)?
    var onCatalogSortOverlayStateChanged: (() -> Void)?

    @Published var searchText = ""
    @Published private(set) var tabs = [TokenPickerV2TabModel]()
    @Published private(set) var selectedChainFilter: TokenPickerV2ChainFilter = .all
    @Published private(set) var currentQueryViewModel: TokenPickerV2QueryViewModel?
    @Published private(set) var showsCatalogSortControl = false
    @Published private(set) var catalogSearchSort: MultichainAssetSearchSort = .marketCap

    var catalogSortButtonTitle: String {
        Self.catalogSortTitle(for: catalogSearchSort)
    }

    private let tokenPickerModel: any TokenPickerV2Model
    private let amountFormatter: AmountFormatter
    private let currencyStore: CurrencyStore

    private var categoryViewModels = [TokenPickerV2ChainFilter: TokenPickerV2CategoryViewModel]()
    private var activateQueryTask: Task<Void, Never>?
    private var hasLoaded = false

    init(
        tokenPickerModel: any TokenPickerV2Model,
        amountFormatter: AmountFormatter,
        currencyStore: CurrencyStore
    ) {
        self.tokenPickerModel = tokenPickerModel
        self.amountFormatter = amountFormatter
        self.currencyStore = currencyStore
    }

    func viewDidLoad() {
        guard let state = tokenPickerModel.initialState() else {
            return
        }

        apply(state: state)
        syncCatalogSortState()
        hasLoaded = true
        activateCurrentQuery()
    }

    func selectCatalogSort(_ sort: MultichainAssetSearchSort) {
        guard tokenPickerModel.showsCatalogSortControl else {
            return
        }
        guard tokenPickerModel.catalogSearchSort != sort else {
            return
        }

        tokenPickerModel.setCatalogSearchSort(sort)
        syncCatalogSortState()

        Task {
            await currentQueryViewModel?.refresh()
        }
    }

    func search(text: String) {
        guard searchText != text else {
            return
        }

        searchText = text
        guard hasLoaded else {
            return
        }
        scheduleQueryActivation(debounced: true)
    }

    func selectChainFilter(_ filter: TokenPickerV2ChainFilter) {
        guard selectedChainFilter != filter else {
            return
        }

        cancelActivateQueryTask()
        selectedChainFilter = filter
        if !searchText.isEmpty {
            searchText = ""
        }

        guard hasLoaded else {
            return
        }
        activateCurrentQuery()
    }

    func selectRow(_ id: String) {
        guard let asset = currentQueryViewModel?.item(withID: id)?.asset else {
            return
        }

        didSelectAsset?(asset)
        didFinish?()
    }

    func close() {
        cancelActivateQueryTask()
        categoryViewModels.values.forEach { $0.disappeared() }
        didFinish?()
    }
}

private extension TokenPickerV2ViewModelImplementation {
    func syncCatalogSortState() {
        showsCatalogSortControl = tokenPickerModel.showsCatalogSortControl
        catalogSearchSort = tokenPickerModel.catalogSearchSort
        onCatalogSortOverlayStateChanged?()
    }

    static func catalogSortTitle(for sort: MultichainAssetSearchSort) -> String {
        switch sort {
        case .marketCap:
            return TKLocales.TokensPicker.Sort.marketCap
        case .volume:
            return TKLocales.TokensPicker.Sort.volume
        }
    }

    var normalizedSearchText: String? {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func apply(state: TokenPickerV2ModelState) {
        categoryViewModels.removeAll()

        tabs = makeTabs(filters: state.filters)
        categoryViewModels = Dictionary(
            uniqueKeysWithValues: state.filters.map { filter in
                (
                    filter,
                    TokenPickerV2CategoryViewModel(
                        category: filter,
                        displayMode: state.displayMode,
                        tokenPickerModel: tokenPickerModel,
                        amountFormatter: amountFormatter,
                        currencyStore: currencyStore
                    )
                )
            }
        )
        if !state.filters.contains(selectedChainFilter) {
            selectedChainFilter = .all
        }
        currentQueryViewModel = categoryViewModels[selectedChainFilter]?.queryViewModel(for: normalizedSearchText)
    }

    func makeTabs(filters: [TokenPickerV2ChainFilter]) -> [TokenPickerV2TabModel] {
        filters.map { filter in
            switch filter {
            case .all:
                return TokenPickerV2TabModel(
                    id: .all,
                    title: TKLocales.History.Tab.all,
                    image: nil,
                    isSelectable: true
                )
            case let .chain(chain):
                return TokenPickerV2TabModel(
                    id: .chain(chain),
                    title: chain.addressConfiguration.title,
                    image: chain.addressConfiguration.icon,
                    isSelectable: true
                )
            }
        }
    }

    func scheduleQueryActivation(debounced: Bool) {
        cancelActivateQueryTask()

        let delay = debounced ? Constants.searchDebounceNanoseconds : 0
        let query = normalizedSearchText
        let filter = selectedChainFilter

        activateQueryTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else {
                return
            }

            self?.activateQuery(
                query: query,
                filter: filter
            )
        }
    }

    func activateCurrentQuery() {
        activateQuery(
            query: normalizedSearchText,
            filter: selectedChainFilter
        )
    }

    func activateQuery(
        query: String?,
        filter: TokenPickerV2ChainFilter
    ) {
        guard let categoryViewModel = categoryViewModels[filter] else {
            return
        }

        let queryViewModel = categoryViewModel.queryViewModel(for: query)
        if currentQueryViewModel !== queryViewModel {
            currentQueryViewModel = queryViewModel
        }
        queryViewModel.appeared()
    }

    func cancelActivateQueryTask() {
        activateQueryTask?.cancel()
        activateQueryTask = nil
    }
}

struct TokenPickerV2TabModel: Identifiable, Hashable {
    let id: TokenPickerV2ChainFilter
    let title: String
    let image: UIImage?
    let isSelectable: Bool
}

enum TokenPickerV2ChainFilter: Hashable {
    case all
    case chain(MultichainChain)
}

extension TokenPickerV2ChainFilter {
    func includes(chain: MultichainChain) -> Bool {
        switch self {
        case .all:
            return true
        case let .chain(expectedChain):
            return expectedChain == chain
        }
    }
}
