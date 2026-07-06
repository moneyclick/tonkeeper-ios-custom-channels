import Foundation
import KeeperCore

enum SendTokenV2PickerDisplayMode {
    case includingMarketData
    case includingSelection(MultichainAsset?)
}

enum SendTokenV2PickerSearchBehavior {
    case catalog
    case account
}

final class SendTokenV2PickerModel: TokenPickerV2Model {
    private let wallet: Wallet
    private let displayMode: SendTokenV2PickerDisplayMode
    private let searchBehavior: SendTokenV2PickerSearchBehavior
    private let multichainService: MultichainService
    private let currencyStore: CurrencyStore

    private(set) var catalogSearchSort: MultichainAssetSearchSort = .marketCap

    var showsCatalogSortControl: Bool {
        searchBehavior == .catalog
    }

    init(
        wallet: Wallet,
        displayMode: SendTokenV2PickerDisplayMode,
        searchBehavior: SendTokenV2PickerSearchBehavior,
        multichainService: MultichainService,
        currencyStore: CurrencyStore
    ) {
        self.wallet = wallet
        self.displayMode = displayMode
        self.searchBehavior = searchBehavior
        self.multichainService = multichainService
        self.currencyStore = currencyStore
    }

    func setCatalogSearchSort(_ sort: MultichainAssetSearchSort) {
        guard searchBehavior == .catalog, catalogSearchSort != sort else {
            return
        }
        catalogSearchSort = sort
    }

    func initialState() -> TokenPickerV2ModelState? {
        let filters = wallet.tokenPickerV2Filters.isEmpty
            ? [.all]
            : wallet.tokenPickerV2Filters

        return TokenPickerV2ModelState(
            filters: filters,
            displayMode: displayMode
        )
    }

    func loadAssets(
        query: String?,
        filter: TokenPickerV2ChainFilter,
        limit: Int,
        cursor: String?
    ) async throws(MultichainServiceError) -> TokenPickerLoadResult {
        let accounts = wallet.tokenPickerV2Accounts(for: filter)
        guard !accounts.isEmpty else {
            return TokenPickerLoadResult(assets: [], nextCursor: nil)
        }

        let normalizedQuery = normalizedQuery(query)

        switch searchBehavior {
        case .catalog:
            return try await loadCatalogAssets(
                query: normalizedQuery,
                filter: filter,
                limit: limit,
                cursor: cursor
            )
        case .account:
            return try await loadAccountAssets(
                query: normalizedQuery,
                filter: filter,
                limit: limit,
                cursor: cursor
            )
        }
    }
}

private extension SendTokenV2PickerModel {
    func loadCatalogAssets(
        query: String?,
        filter: TokenPickerV2ChainFilter,
        limit: Int,
        cursor: String?
    ) async throws(MultichainServiceError) -> TokenPickerLoadResult {
        let walletAssetById = try await walletAssetsByIdForMergingBalances()
        let currencyCodes = requestedCurrencyCodes(for: currencyStore.state)
        let page = try await multichainService.searchAssets(
            currencies: currencyCodes,
            chain: apiChain(for: filter),
            search: query,
            sort: catalogSearchSort,
            limit: limit,
            cursor: cursor
        )
        let merged = page.assets.map { asset in
            MultichainAsset(
                asset: asset.asset,
                price: asset.price,
                balance: walletAssetById[asset.asset.assetId]?.balance ?? .zero,
                marketCap: asset.marketCap
            )
        }
        return TokenPickerLoadResult(
            assets: prioritizedAssets(merged, isFirstPage: cursor == nil),
            nextCursor: page.nextCursor
        )
    }

    func loadAccountAssets(
        query: String?,
        filter: TokenPickerV2ChainFilter,
        limit: Int,
        cursor: String?
    ) async throws(MultichainServiceError) -> TokenPickerLoadResult {
        let currencyCodes = requestedCurrencyCodes(for: currencyStore.state)
        let page = try await multichainService.getWalletAssets(
            walletId: wallet.id,
            currencies: currencyCodes,
            chain: nil,
            search: nil,
            availableOnly: nil,
            showHidden: nil,
            limit: limit,
            cursor: cursor
        )
        let filteredAssets = page.assets.filter {
            matchesFilter(filter, asset: $0) && matchesQuery(query, asset: $0)
        }
        return TokenPickerLoadResult(
            assets: prioritizedAssets(filteredAssets, isFirstPage: cursor == nil),
            nextCursor: page.nextCursor
        )
    }

    func normalizedQuery(_ query: String?) -> String? {
        guard let query else {
            return nil
        }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func walletAssetsByIdForMergingBalances() async throws(MultichainServiceError) -> [String: MultichainAsset] {
        var map: [String: MultichainAsset] = [:]
        let currencyCodes = requestedCurrencyCodes(for: currencyStore.state)
        let assets = try await multichainService.getWalletAssets(
            walletId: wallet.id,
            currencies: currencyCodes,
            chain: nil,
            search: nil,
            availableOnly: nil,
            showHidden: nil,
            limit: nil,
            cursor: nil
        ).assets
        for asset in assets {
            map[asset.asset.assetId] = asset
        }
        return map
    }

    func requestedCurrencyCodes(for currency: Currency) -> [String] {
        var codes = [currency.code.lowercased()]
        if currency != .defaultCurrency {
            codes.append(Currency.defaultCurrency.code.lowercased())
        }
        return codes
    }

    func matchesFilter(
        _ filter: TokenPickerV2ChainFilter,
        asset: MultichainAsset
    ) -> Bool {
        guard let chain = asset.asset.chain else {
            return true
        }
        return filter.includes(chain: chain)
    }

    func matchesQuery(
        _ query: String?,
        asset: MultichainAsset
    ) -> Bool {
        guard let query else {
            return true
        }

        return [
            asset.asset.name,
            asset.asset.symbol,
            asset.asset.assetId,
        ].contains {
            $0.localizedCaseInsensitiveContains(query)
        }
    }

    func apiChain(for filter: TokenPickerV2ChainFilter) -> MultichainChain? {
        switch filter {
        case .all:
            return nil
        case let .chain(chain):
            return chain
        }
    }

    func prioritizedAssets(
        _ assets: [MultichainAsset],
        isFirstPage: Bool
    ) -> [MultichainAsset] {
        let selectedAsset: MultichainAsset?
        switch displayMode {
        case let .includingSelection(asset):
            selectedAsset = asset
        case .includingMarketData:
            selectedAsset = nil
        }
        guard
            isFirstPage,
            let selectedAsset,
            let index = assets.lazy.map(\.asset.assetId).firstIndex(
                of: selectedAsset.asset.assetId
            ),
            index > 0
        else {
            return assets
        }

        var prioritizedAssets = assets
        prioritizedAssets.insert(
            prioritizedAssets.remove(at: index),
            at: 0
        )
        return prioritizedAssets
    }
}
