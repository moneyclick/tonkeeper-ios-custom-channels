import Foundation
import KeeperCore
import TKLocalize
import TKUIKit
import UIKit

enum MultichainHistoryChainFilter: Hashable {
    case all
    case chain(MultichainChain)

    var apiChain: MultichainChain? {
        switch self {
        case .all:
            return nil
        case let .chain(chain):
            return chain
        }
    }
}

enum MultichainHistoryTypeFilter: Hashable, CaseIterable {
    case all
    case send
    case receive
    case swap

    var title: String {
        switch self {
        case .all:
            return TKLocales.History.Tab.all
        case .send:
            return TKLocales.History.Tab.sent
        case .receive:
            return TKLocales.History.Tab.received
        case .swap:
            return TKLocales.ActionTypes.Future.swap
        }
    }

    var apiActivityType: MultichainActivityType? {
        switch self {
        case .all:
            return nil
        case .send:
            return .send
        case .receive:
            return .receive
        case .swap:
            return .swap
        }
    }
}

struct MultichainHistoryCategory: Hashable {
    let chainFilter: MultichainHistoryChainFilter
    let typeFilter: MultichainHistoryTypeFilter

    var apiChain: MultichainChain? {
        chainFilter.apiChain
    }

    var apiActivityType: MultichainActivityType? {
        typeFilter.apiActivityType
    }
}

struct MultichainHistoryChainTab: Identifiable, Equatable {
    let id: MultichainHistoryChainFilter
    let title: String
    let image: UIImage?
    let isSelectable: Bool

    static func == (lhs: MultichainHistoryChainTab, rhs: MultichainHistoryChainTab) -> Bool {
        lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.isSelectable == rhs.isSelectable
    }
}

struct MultichainHistoryTypeFilterItem: Identifiable, Equatable {
    let id: MultichainHistoryTypeFilter
    let title: String
    let isSelected: Bool
}

struct MultichainHistoryActivityItem: Identifiable, Equatable {
    struct Amount: Equatable {
        enum Style: Equatable {
            case primary
            case positive
            case negative
        }

        let text: String
        let style: Style
    }

    let id: MultichainActivity
    let activity: MultichainActivity
    let title: String
    let subtitle: String?
    let time: String
    let icon: UIImage
    let primaryAmount: Amount?
    let secondaryAmount: Amount?
    let status: MultichainActivityStatus

    static func == (lhs: MultichainHistoryActivityItem, rhs: MultichainHistoryActivityItem) -> Bool {
        lhs.id == rhs.id
            && lhs.activity == rhs.activity
            && lhs.title == rhs.title
            && lhs.subtitle == rhs.subtitle
            && lhs.time == rhs.time
            && lhs.primaryAmount == rhs.primaryAmount
            && lhs.secondaryAmount == rhs.secondaryAmount
            && lhs.status == rhs.status
    }
}

struct MultichainHistorySection: Identifiable, Equatable {
    let id: Date
    let title: String
    let items: [MultichainHistoryActivityItem]
}

extension Wallet {
    var multichainHistoryChainFilters: [MultichainHistoryChainFilter] {
        guard case let .addresses(addresses) = multichain else {
            return [.all]
        }

        var filters: [MultichainHistoryChainFilter] = [.all]
        var seenChains = Set<MultichainChain>()

        for address in addresses {
            guard seenChains.insert(address.chain).inserted else {
                continue
            }
            filters.append(.chain(address.chain))
        }

        return filters
    }
}
