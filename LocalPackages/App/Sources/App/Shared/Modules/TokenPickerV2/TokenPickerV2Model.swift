import Foundation
import KeeperCore

struct TokenPickerLoadResult: Equatable {
    let assets: [MultichainAsset]
    let nextCursor: String?
}

protocol TokenPickerV2Model: AnyObject {
    func initialState() -> TokenPickerV2ModelState?

    func loadAssets(
        query: String?,
        filter: TokenPickerV2ChainFilter,
        limit: Int,
        cursor: String?
    ) async throws(MultichainServiceError) -> TokenPickerLoadResult

    var showsCatalogSortControl: Bool { get }
    var catalogSearchSort: MultichainAssetSearchSort { get }
    func setCatalogSearchSort(_ sort: MultichainAssetSearchSort)
}

struct TokenPickerV2ModelState {
    let filters: [TokenPickerV2ChainFilter]
    let displayMode: SendTokenV2PickerDisplayMode
}

extension Wallet {
    var tokenPickerV2Filters: [TokenPickerV2ChainFilter] {
        guard case let .addresses(addresses) = multichain else {
            return []
        }

        var filters: [TokenPickerV2ChainFilter] = [.all]
        var seenChains = Set<MultichainChain>()

        for address in addresses {
            guard seenChains.insert(address.chain).inserted else {
                continue
            }
            filters.append(.chain(address.chain))
        }

        return filters
    }

    func tokenPickerV2Accounts(
        for filter: TokenPickerV2ChainFilter
    ) -> [MultichainAccount] {
        guard case let .addresses(addresses) = multichain else {
            return []
        }

        return addresses.compactMap { address -> MultichainAccount? in
            guard filter.includes(chain: address.chain) else {
                return nil
            }

            return MultichainAccount(
                chain: address.chain,
                network: .mainnet,
                address: address.address
            )
        }
    }
}
