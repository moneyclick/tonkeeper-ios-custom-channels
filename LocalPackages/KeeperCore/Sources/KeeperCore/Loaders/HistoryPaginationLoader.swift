import Foundation
import TonSwift

public final class HistoryPaginationLoader: @unchecked Sendable {
    public enum Event {
        case initialLoading
        case initialLoadingFailed
        case initialLoaded([HistoryEvent], hasMore: Bool)
        case pageLoading
        case pageLoadingFailed
        case pageLoaded([HistoryEvent], hasMore: Bool)
    }

    public var eventHandler: ((Event) -> Void)?

    private enum State {
        case idle
        case loading(id: UUID, task: Task<Void, Never>)
    }

    private let queue = DispatchQueue(label: "HistoryPaginationLoaderQueue")
    private var state: State = .idle
    private var nextFrom: Int64?
    private var lastReloadDate: Date?
    private var pagination = HistoryListLoaderPagination(
        tonEventsBeforeLt: nil,
        tronEventsMaxTimestamp: nil,
        tonHasMore: true,
        tronHasMore: true
    )

    private let wallet: Wallet
    private let loader: HistoryListLoader
    private let nftService: NFTService

    init(
        wallet: Wallet,
        loader: HistoryListLoader,
        nftService: NFTService
    ) {
        self.wallet = wallet
        self.loader = loader
        self.nftService = nftService
    }

    private func isCurrentLoad(id: UUID) -> Bool {
        guard case let .loading(currentID, _) = state else {
            return false
        }
        return currentID == id
    }

    public func reload(force: Bool) {
        queue.async {
            let needToReload: Bool = {
                guard let lastReloadDate = self.lastReloadDate else {
                    return true
                }
                let currentDate = Date()
                let diff = currentDate.timeIntervalSince(lastReloadDate)
                return diff >= .notForceReloadDelay
            }()

            guard needToReload || force else {
                return
            }

            if case let .loading(_, task) = self.state {
                task.cancel()
            }
            let pagination = HistoryListLoaderPagination(
                tonEventsBeforeLt: nil,
                tronEventsMaxTimestamp: nil,
                tonHasMore: true,
                tronHasMore: true
            )
            self.lastReloadDate = Date()
            let loadID = UUID()

            let task = Task {
                do {
                    let events = try await self.loadNextPage(pagination: pagination)
                    try Task.checkCancellation()
                    self.queue.async { [events] in
                        guard self.isCurrentLoad(id: loadID) else { return }
                        let nextPagination = Self.makeNextPagination(previous: pagination, batch: events)
                        self.pagination = nextPagination
                        let historyEvents = self.handleLoadedBatch(batch: events)
                        self.eventHandler?(.initialLoaded(historyEvents, hasMore: nextPagination.hasMore))
                        self.state = .idle
                    }
                } catch {
                    self.queue.async {
                        guard self.isCurrentLoad(id: loadID) else { return }
                        guard !error.isCancelledError else {
                            self.state = .idle
                            return
                        }
                        self.eventHandler?(.initialLoadingFailed)
                        self.state = .idle
                    }
                }
            }

            self.eventHandler?(.initialLoading)
            self.state = .loading(id: loadID, task: task)
        }
    }

    public func loadNext() {
        queue.async {
            guard case .idle = self.state else {
                return
            }
            guard self.pagination.hasMore else { return }

            let pagination = self.pagination
            let loadID = UUID()

            let task = Task {
                do {
                    let events = try await self.loadNextPage(pagination: pagination)
                    try Task.checkCancellation()
                    self.queue.async {
                        guard self.isCurrentLoad(id: loadID) else { return }
                        let nextPagination = Self.makeNextPagination(previous: pagination, batch: events)
                        self.pagination = nextPagination

                        let historyEvents = self.handleLoadedBatch(batch: events)
                        self.eventHandler?(.pageLoaded(historyEvents, hasMore: nextPagination.hasMore))
                        self.state = .idle
                    }
                } catch {
                    self.queue.async {
                        guard self.isCurrentLoad(id: loadID) else { return }
                        guard !error.isCancelledError else {
                            self.state = .idle
                            return
                        }
                        self.eventHandler?(.pageLoadingFailed)
                        self.state = .idle
                    }
                }
            }

            self.eventHandler?(.pageLoading)
            self.state = .loading(id: loadID, task: task)
        }
    }

    func loadNextPage(pagination: HistoryListLoaderPagination) async throws -> HistoryEventsBatch {
        let events = try await loader.loadEvents(
            wallet: wallet,
            pagination: pagination,
            limit: .limit
        )
        try Task.checkCancellation()
        await handleEventsWithNFTs(events: events.accountsEvents?.events ?? [])
        return events
    }

    func handleEventsWithNFTs(events: [AccountEvent]) async {
        let actions = events.flatMap { $0.actions }
        var nftAddressesToLoad = Set<Address>()
        for action in actions {
            switch action.type {
            case let .nftItemTransfer(nftItemTransfer):
                nftAddressesToLoad.insert(nftItemTransfer.nftAddress)
            case let .nftPurchase(nftPurchase):
                try? nftService.saveNFT(nft: nftPurchase.nft, network: wallet.network)
            default: continue
            }
        }
        guard !nftAddressesToLoad.isEmpty else { return }
        _ = try? await nftService.loadNFTs(addresses: Array(nftAddressesToLoad), network: wallet.network)
    }

    private static func makeNextPagination(
        previous: HistoryListLoaderPagination,
        batch: HistoryEventsBatch
    ) -> HistoryListLoaderPagination {
        let tonFailed = batch.accountsEvents == nil
        let tronFailed = batch.tronTransactions == nil

        let tonHasMore: Bool
        if tonFailed {
            tonHasMore = true
        } else if let nextFrom = batch.accountsEvents?.nextFrom {
            tonHasMore = nextFrom != 0
        } else {
            tonHasMore = false
        }

        let tronHasMore: Bool
        if tronFailed {
            tronHasMore = false
        } else {
            tronHasMore = (batch.tronTransactions?.count ?? 0) >= .limit
        }

        return HistoryListLoaderPagination(
            tonEventsBeforeLt: tonFailed ? previous.tonEventsBeforeLt : batch.accountsEvents?.nextFrom,
            tronEventsMaxTimestamp: tronFailed
                ? previous.tronEventsMaxTimestamp
                : (batch.tronTransactions?.last?.timestamp ?? previous.tronEventsMaxTimestamp),
            tonHasMore: tonHasMore,
            tronHasMore: tronHasMore
        )
    }

    func handleLoadedBatch(batch: HistoryEventsBatch) -> [HistoryEvent] {
        let tonHistoryEvents = (batch.accountsEvents?.events ?? []).map { HistoryEvent.tonAccountEvent($0) }
        let tronHistoryEvents = (batch.tronTransactions ?? []).map { HistoryEvent.tronEvent($0) }
        let events = tonHistoryEvents + tronHistoryEvents
        return events.sorted(by: { $0.timestamp > $1.timestamp })
    }
}

private extension Int {
    static let limit: Int = 20
}

private extension TimeInterval {
    static let notForceReloadDelay: TimeInterval = 1
}
