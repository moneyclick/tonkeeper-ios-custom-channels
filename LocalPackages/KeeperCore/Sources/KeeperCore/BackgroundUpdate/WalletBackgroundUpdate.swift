import EventSource
import Foundation
import TKLogging
import TonStreamingAPI
import TonStreamingAPIV2

public final class WalletBackgroundUpdate {
    @Atomic public var eventClosure: ((BackgroundUpdateEvent) -> Void)?
    @Atomic public var stateClosure: ((BackgroundUpdateConnectionState) -> Void)?

    @Atomic public var state: BackgroundUpdateConnectionState = .connecting {
        didSet {
            logState(state: state)
            stateClosure?(state)
        }
    }

    @Atomic private var eventId: String?
    private var task: Task<Void, Never>?

    private let jsonDecoder = JSONDecoder()

    private let wallet: Wallet
    private let streamingAPI: TonStreamingAPI.StreamingAPI?
    private let streamingAPIV2Provider: StreamingAPIV2Provider

    init(
        wallet: Wallet,
        streamingAPIProvider: StreamingAPIProvider,
        streamingAPIV2Provider: StreamingAPIV2Provider
    ) {
        self.wallet = wallet
        self.streamingAPI = streamingAPIProvider.api(wallet.network)
        self.streamingAPIV2Provider = streamingAPIV2Provider
    }

    func start() {
        self.task?.cancel()

        self.task = makeTask {
            if let api = await self.streamingAPIV2Provider.api(self.wallet.network) {
                try await self.startV2(api: api)
                return true
            }

            if let api = self.streamingAPI {
                try await self.startV1(api: api)
                return true
            }

            self.state = .connected
            return false
        }
    }

    func stop() {
        task?.cancel()
    }

    private func makeTask(
        operation: @escaping @Sendable () async throws -> Bool
    ) -> Task<Void, Never> {
        Task {
            do {
                let shouldRestart = try await operation()

                guard shouldRestart else {
                    return
                }

                self.state = .disconnected

                try Task.checkCancellation()
                await MainActor.run {
                    start()
                }
            } catch {
                guard !error.isCancelledError else { return }
                if error.isNoConnectionError {
                    state = .noConnection
                } else {
                    state = .disconnected
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await MainActor.run {
                        self.start()
                    }
                }
            }
        }
    }

    private func startV1(api: TonStreamingAPI.StreamingAPI) async throws {
        let address = try wallet.address

        self.state = .connecting

        let stream = try await api.accountTransactionsStream(account: address.toRaw())
        try Task.checkCancellation()
        self.state = .connected

        for try await events in stream {
            handleReceivedV1Events(events)
        }
    }

    private func startV2(api: TonStreamingAPIV2.StreamingAPI) async throws {
        let address = try wallet.address

        self.state = .connecting

        let request = TonStreamingAPIV2.SseSubscriptionRequest(
            addresses: [address.toRaw()],
            types: [.transactions, .actions, .accountStateChange, .jettonsChange],
            minFinality: .pending
        )

        let stream = try await api.stream(sseSubscriptionRequest: request)
        try Task.checkCancellation()
        self.state = .connected

        for try await payloads in stream {
            handleReceivedV2Payloads(payloads)
        }
    }

    private func handleReceivedV1Events(_ events: [EventSource.Event]) {
        guard let messageEvent = events.last(where: { $0.event == "message" }),
              let eventId = messageEvent.id,
              let eventData = messageEvent.data?.data(using: .utf8)
        else {
            return
        }

        self.eventId = eventId

        do {
            let eventTransaction = try jsonDecoder.decode(EventSource.Transaction.self, from: eventData)
            let event = BackgroundUpdateEvent(
                wallet: wallet,
                lt: eventTransaction.lt,
                txHash: eventTransaction.txHash
            )
            eventClosure?(event)
        } catch {
            return
        }
    }

    private func handleReceivedV2Payloads(_ payloads: [TonStreamingAPIV2.SseJsonPayload]) {
        guard let event = payloads.compactMap(backgroundUpdateEvent).last else {
            return
        }

        eventClosure?(event)
    }

    private func backgroundUpdateEvent(
        from payload: TonStreamingAPIV2.SseJsonPayload
    ) -> BackgroundUpdateEvent? {
        guard case let .typeStreamEvent(streamEvent) = payload else {
            return nil
        }

        guard case let .typeTransactionsNotification(notification) = streamEvent else {
            return nil
        }

        return backgroundUpdateEvent(from: notification)
    }

    private func backgroundUpdateEvent(
        from notification: TonStreamingAPIV2.TransactionsNotification
    ) -> BackgroundUpdateEvent? {
        let parsedTransactions = notification.transactions.compactMap { transaction in
            parseTransaction(transaction.mapValues(\.value))
        }

        guard let newestTransaction = parsedTransactions.max(by: { $0.lt < $1.lt }) else {
            return nil
        }

        return BackgroundUpdateEvent(
            wallet: wallet,
            lt: newestTransaction.lt,
            txHash: newestTransaction.txHash
        )
    }

    private func parseTransaction(_ object: [String: Any]) -> (lt: Int64, txHash: String)? {
        guard let lt = int64Value(from: object["lt"]) else {
            return nil
        }

        let txHash = stringValue(from: object["tx_hash"]) ?? stringValue(from: object["hash"])
        guard let txHash else {
            return nil
        }

        return (lt: lt, txHash: txHash)
    }

    private func int64Value(from value: Any?) -> Int64? {
        switch value {
        case let value as Int64:
            return value
        case let value as Int:
            return Int64(value)
        case let value as Int32:
            return Int64(value)
        case let value as UInt64:
            return Int64(exactly: value)
        case let value as UInt:
            return Int64(exactly: value)
        case let value as Double:
            return Int64(exactly: value)
        case let value as String:
            return Int64(value)
        default:
            return nil
        }
    }

    private func stringValue(from value: Any?) -> String? {
        switch value {
        case let value as String:
            return value
        case let value as CustomStringConvertible:
            return value.description
        default:
            return nil
        }
    }

    private func logState(state: BackgroundUpdateConnectionState) {
        switch state {
        case .connecting:
            Log.i("Log 🪵: WalletBackgroundUpdate - \(wallet.label) — connecting")
        case .connected:
            Log.i("Log 🪵: WalletBackgroundUpdate - \(wallet.label) — connected")
        case .disconnected:
            Log.i("Log 🪵: WalletBackgroundUpdate - \(wallet.label) — disconnected")
        case .noConnection:
            Log.i("Log 🪵: WalletBackgroundUpdate - \(wallet.label) — no connection")
        }
    }
}
