import Foundation
import KeeperCore
import TKLocalize
import TKUIKit
import UIKit

@MainActor
final class MultichainHistoryQueryViewModel: ObservableObject {
    private enum Constants {
        static let pageSize = 30
        static let loadMoreThreshold = 5
    }

    struct RowData: Equatable {
        var items: [MultichainHistoryActivityItem]
        var nextCursor: String?
        var hasNextPage: Bool

        static var initial: RowData {
            RowData(items: [], nextCursor: nil, hasNextPage: false)
        }
    }

    enum State {
        case idle
        case refreshing(
            rowData: RowData,
            task: Task<Void, Never>
        )
        case loaded(
            rowData: RowData
        )
        case loadingMore(
            rowData: RowData,
            task: Task<Void, Never>
        )
        case failed(
            rowData: RowData,
            errorMessage: String?
        )
    }

    enum Placeholder: Equatable {
        case empty
        case error(String?)
    }

    struct Presentation: Equatable {
        let sections: [MultichainHistorySection]
        let isLoadingMore: Bool
        let showsSkeleton: Bool
        let placeholder: Placeholder?
    }

    @Published private(set) var state: State = .idle

    private let walletId: String
    private let category: MultichainHistoryCategory
    private let multichainService: MultichainService
    private let signedAmountFormatter: AmountFormatter
    private let dateFormatter: DateFormatter
    private let currentDateProvider: () -> Date
    private let onAddFunds: () -> Void

    init(
        walletId: String,
        category: MultichainHistoryCategory,
        multichainService: MultichainService,
        amountFormatter: AmountFormatter,
        dateFormatter: DateFormatter,
        currentDateProvider: @escaping () -> Date = Date.init,
        onAddFunds: @escaping () -> Void = {}
    ) {
        self.walletId = walletId
        self.category = category
        self.multichainService = multichainService
        var signedConfiguration = amountFormatter.config
        signedConfiguration.signPolicy = .always
        self.signedAmountFormatter = AmountFormatter(configuration: signedConfiguration)
        self.dateFormatter = dateFormatter
        self.currentDateProvider = currentDateProvider
        self.onAddFunds = onAddFunds
    }

    var presentation: Presentation {
        Self.presentation(
            for: state,
            sectionTitleProvider: sectionTitle(for:),
            currentDate: currentDateProvider(),
            calendar: sectionCalendar
        )
    }

    var hasActivityItems: Bool {
        switch state {
        case .idle:
            return false
        case let .refreshing(rowData, _),
             let .loaded(rowData),
             let .loadingMore(rowData, _),
             let .failed(rowData, _):
            return !rowData.items.isEmpty
        }
    }

    static func presentation(
        for state: State,
        sectionTitleProvider: (Date) -> String,
        currentDate: Date,
        calendar: Calendar
    ) -> Presentation {
        switch state {
        case .idle:
            return Presentation(
                sections: [],
                isLoadingMore: false,
                showsSkeleton: true,
                placeholder: nil
            )
        case let .refreshing(rowData, _):
            if rowData == .initial {
                return Presentation(
                    sections: [],
                    isLoadingMore: false,
                    showsSkeleton: true,
                    placeholder: nil
                )
            }
            return Presentation(
                sections: makeSections(
                    items: rowData.items,
                    titleProvider: sectionTitleProvider,
                    currentDate: currentDate,
                    calendar: calendar
                ),
                isLoadingMore: false,
                showsSkeleton: false,
                placeholder: rowData.items.isEmpty ? .empty : nil
            )
        case let .loaded(rowData):
            return Presentation(
                sections: makeSections(
                    items: rowData.items,
                    titleProvider: sectionTitleProvider,
                    currentDate: currentDate,
                    calendar: calendar
                ),
                isLoadingMore: false,
                showsSkeleton: false,
                placeholder: rowData.items.isEmpty ? .empty : nil
            )
        case let .loadingMore(rowData, _):
            return Presentation(
                sections: makeSections(
                    items: rowData.items,
                    titleProvider: sectionTitleProvider,
                    currentDate: currentDate,
                    calendar: calendar
                ),
                isLoadingMore: true,
                showsSkeleton: rowData == .initial,
                placeholder: rowData.items.isEmpty ? .empty : nil
            )
        case let .failed(rowData, errorMessage):
            return Presentation(
                sections: makeSections(
                    items: rowData.items,
                    titleProvider: sectionTitleProvider,
                    currentDate: currentDate,
                    calendar: calendar
                ),
                isLoadingMore: false,
                showsSkeleton: false,
                placeholder: rowData.items.isEmpty ? .error(errorMessage) : nil
            )
        }
    }

    func appeared() {
        switch state {
        case .idle:
            let task = Task {
                await loadFirstPage(fallbackData: .initial)
            }
            state = .refreshing(rowData: .initial, task: task)
        default:
            break
        }
    }

    func disappeared() {
        let fallbackData: RowData
        switch state {
        case .idle:
            return
        case let .loaded(rowData), let .failed(rowData, _):
            fallbackData = rowData
        case let .refreshing(rowData, task), let .loadingMore(rowData, task):
            task.cancel()
            fallbackData = rowData
        }

        if fallbackData == .initial {
            state = .idle
        } else {
            state = .loaded(rowData: fallbackData)
        }
    }

    func addFunds() {
        onAddFunds()
    }

    func refresh() async {
        let rowData: RowData
        switch state {
        case .idle:
            rowData = .initial
        case let .loaded(data), let .failed(data, _):
            rowData = data
        case let .refreshing(data, task), let .loadingMore(data, task):
            task.cancel()
            rowData = data
        }

        let task = Task {
            await loadFirstPage(fallbackData: rowData)
        }
        state = .refreshing(rowData: rowData, task: task)
        await task.value
    }

    func loadNextPageIfNeeded(currentItem: MultichainHistoryActivityItem) {
        guard case let .loaded(rowData) = state else {
            return
        }
        guard rowData.hasNextPage else {
            return
        }
        guard let currentIndex = rowData.items.firstIndex(where: { $0.id == currentItem.id }) else {
            return
        }

        let thresholdIndex = max(rowData.items.count - Constants.loadMoreThreshold, 0)
        guard currentIndex >= thresholdIndex else {
            return
        }

        state = .loadingMore(
            rowData: rowData,
            task: Task {
                await loadNextPage(fallbackData: rowData)
            }
        )
    }
}

private extension MultichainHistoryQueryViewModel {
    func loadFirstPage(fallbackData: RowData) async {
        let page: MultichainWalletActivitiesPage
        do {
            page = try await loadPage(cursor: nil)
        } catch {
            guard !Task.isCancelled, !isCancelled(error) else {
                return
            }
            state = .failed(
                rowData: fallbackData,
                errorMessage: errorMessage(from: error)
            )
            return
        }

        guard !Task.isCancelled else {
            return
        }

        let activities = deduplicated(page.activities)
        state = .loaded(
            rowData: RowData(
                items: activities.map(makeItem),
                nextCursor: page.nextCursor,
                hasNextPage: page.nextCursor != nil
            )
        )
    }

    func loadNextPage(fallbackData: RowData) async {
        let page: MultichainWalletActivitiesPage
        do {
            page = try await loadPage(cursor: fallbackData.nextCursor)
        } catch {
            guard !Task.isCancelled, !isCancelled(error) else {
                return
            }
            state = .failed(
                rowData: fallbackData,
                errorMessage: errorMessage(from: error)
            )
            return
        }

        guard !Task.isCancelled else {
            return
        }

        let mergedActivities = deduplicated(
            fallbackData.items.map(\.activity) + page.activities
        )
        state = .loaded(
            rowData: RowData(
                items: mergedActivities.map(makeItem),
                nextCursor: page.nextCursor,
                hasNextPage: page.nextCursor != nil
            )
        )
    }

    func loadPage(cursor: String?) async throws(MultichainServiceError) -> MultichainWalletActivitiesPage {
        try await multichainService.getWalletActivities(
            walletId: walletId,
            limit: Constants.pageSize,
            cursor: cursor,
            chain: category.apiChain,
            activityType: category.apiActivityType
        )
    }

    func deduplicated(_ activities: [MultichainActivity]) -> [MultichainActivity] {
        var seen = Set<MultichainActivity>()
        seen.reserveCapacity(activities.count)

        var result = [MultichainActivity]()
        result.reserveCapacity(activities.count)

        for activity in activities {
            guard seen.insert(activity).inserted else {
                continue
            }
            result.append(activity)
        }
        return result
    }

    func makeItem(activity: MultichainActivity) -> MultichainHistoryActivityItem {
        MultichainHistoryActivityItem(
            id: activity,
            activity: activity,
            title: title(for: activity),
            subtitle: subtitle(for: activity),
            time: timeString(for: activity.blockTime),
            icon: icon(for: activity),
            primaryAmount: primaryAmount(for: activity),
            secondaryAmount: secondaryAmount(for: activity),
            status: activity.status
        )
    }

    func title(for activity: MultichainActivity) -> String {
        switch activity.activityType {
        case .send:
            return TKLocales.History.Tab.sent
        case .receive:
            return TKLocales.History.Tab.received
        case .swap:
            return TKLocales.ActionTypes.Future.swap
        }
    }

    func subtitle(for activity: MultichainActivity) -> String? {
        let address: String?
        switch activity.direction {
        case .incoming:
            address = activity.fromAddress ?? activity.walletAddress
        case .outgoing:
            address = activity.toAddress ?? activity.walletAddress
        case .selfTransfer:
            address = activity.walletAddress ?? activity.toAddress ?? activity.fromAddress
        }

        if let address {
            return address.shortMultichainHistoryAddress
        }

        return activity.protocolName
    }

    func icon(for activity: MultichainActivity) -> UIImage {
        switch activity.activityType {
        case .send:
            return .App.Icons.Size28.trayArrowUp
        case .receive:
            return .App.Icons.Size28.trayArrowDown
        case .swap:
            return .App.Icons.Size28.swapHorizontalAlternative
        }
    }

    func primaryAmount(for activity: MultichainActivity) -> MultichainHistoryActivityItem.Amount? {
        switch activity.activityType {
        case .send:
            return amount(
                rawAmount: activity.outAmount,
                token: activity.outToken,
                sign: .negative
            )
        case .receive:
            return amount(
                rawAmount: activity.inAmount,
                token: activity.inToken,
                sign: .positive
            )
        case .swap:
            return amount(
                rawAmount: activity.inAmount,
                token: activity.inToken,
                sign: .positive
            )
        }
    }

    func secondaryAmount(for activity: MultichainActivity) -> MultichainHistoryActivityItem.Amount? {
        guard activity.activityType == .swap else {
            return nil
        }

        return amount(
            rawAmount: activity.outAmount,
            token: activity.outToken,
            sign: .negative
        )
    }

    enum AmountSign {
        case positive
        case negative
    }

    func amount(
        rawAmount: String?,
        token: MultichainAssetDetails?,
        sign: AmountSign
    ) -> MultichainHistoryActivityItem.Amount? {
        guard let rawAmount, let token else {
            return nil
        }

        let signedAmount = signedDecimal(from: rawAmount, sign: sign)
        let title: String
        if let signedAmount {
            title = signedAmountFormatter.format(
                decimal: signedAmount,
                accessory: .tokenSymbol(token.symbol),
                style: .compact
            )
        } else {
            title = fallbackAmountTitle(
                rawAmount: rawAmount,
                token: token,
                sign: sign
            )
        }
        let chainTitle: String?
        switch AssetIdComponents(assetId: token.assetId) {
        case .coin:
            chainTitle = nil
        default:
            chainTitle = token.chain?.symbol
        }
        let text = [title, chainTitle]
            .compactMap { $0 }
            .joined(separator: " ")

        switch sign {
        case .positive:
            return MultichainHistoryActivityItem.Amount(
                text: text,
                style: .positive
            )
        case .negative:
            return MultichainHistoryActivityItem.Amount(
                text: text,
                style: .negative
            )
        }
    }

    func signedDecimal(
        from rawAmount: String,
        sign: AmountSign
    ) -> Decimal? {
        guard var decimal = decimalValue(from: rawAmount) else {
            return nil
        }

        switch sign {
        case .positive:
            decimal = abs(decimal)
        case .negative:
            decimal = -abs(decimal)
        }
        return decimal
    }

    func fallbackAmountTitle(
        rawAmount: String,
        token: MultichainAssetDetails,
        sign: AmountSign
    ) -> String {
        let signPrefix: String
        switch sign {
        case .positive:
            signPrefix = "+"
        case .negative:
            signPrefix = "−"
        }
        return "\(signPrefix)\(rawAmount) \(token.symbol)"
    }

    func decimalValue(from value: String) -> Decimal? {
        let normalized = value
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789.+-".contains($0) }

        guard !normalized.isEmpty else {
            return nil
        }

        return Decimal(
            string: normalized,
            locale: Locale(identifier: "en_US_POSIX")
        )
    }

    func timeString(for date: Date) -> String {
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date)
    }

    func sectionTitle(for date: Date) -> String {
        let calendar = sectionCalendar
        let currentDate = currentDateProvider()
        if calendar.isDate(date, inSameDayAs: currentDate) {
            return TKLocales.Dates.today
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate),
           calendar.isDate(date, inSameDayAs: yesterday)
        {
            return TKLocales.Dates.yesterday
        }

        if calendar.isDate(date, equalTo: currentDate, toGranularity: .month) {
            dateFormatter.dateFormat = "d MMMM"
        } else if calendar.isDate(date, equalTo: currentDate, toGranularity: .year) {
            dateFormatter.dateFormat = "LLLL"
        } else {
            dateFormatter.dateFormat = "LLLL y"
        }
        return dateFormatter.string(from: date).capitalized
    }

    var sectionCalendar: Calendar {
        var calendar = dateFormatter.calendar ?? Calendar.current
        if let timeZone = dateFormatter.timeZone {
            calendar.timeZone = timeZone
        }
        return calendar
    }

    func isCancelled(_ error: MultichainServiceError) -> Bool {
        if case .cancelled = error {
            return true
        }
        return false
    }

    func errorMessage(from error: MultichainServiceError) -> String? {
        switch error {
        case .cancelled:
            return nil
        case .connectionError:
            return TKLocales.ConnectionStatus.noInternet
        case let .apiError(message):
            return message
        }
    }
}

private extension MultichainHistoryQueryViewModel {
    static func makeSections(
        items: [MultichainHistoryActivityItem],
        titleProvider: (Date) -> String,
        currentDate: Date,
        calendar: Calendar
    ) -> [MultichainHistorySection] {
        var sections = [MultichainHistorySection]()
        var sectionIndexes = [Date: Int]()

        for item in items {
            guard let sectionDate = sectionDate(
                for: item.activity.blockTime,
                currentDate: currentDate,
                calendar: calendar
            ) else {
                continue
            }

            if let sectionIndex = sectionIndexes[sectionDate] {
                var section = sections[sectionIndex]
                section = MultichainHistorySection(
                    id: section.id,
                    title: section.title,
                    items: section.items + [item]
                )
                sections[sectionIndex] = section
            } else {
                let section = MultichainHistorySection(
                    id: sectionDate,
                    title: titleProvider(sectionDate),
                    items: [item]
                )
                sectionIndexes[sectionDate] = sections.count
                sections.append(section)
            }
        }

        return sections
    }

    static func sectionDate(
        for date: Date,
        currentDate: Date,
        calendar: Calendar
    ) -> Date? {
        let components: Set<Calendar.Component> = if calendar.isDate(date, equalTo: currentDate, toGranularity: .month) {
            [.year, .month, .day]
        } else {
            [.year, .month]
        }

        return calendar.date(
            from: calendar.dateComponents(
                components,
                from: date
            )
        )
    }
}

private extension String {
    var shortMultichainHistoryAddress: String {
        guard count > 14 else {
            return self
        }
        return "\(prefix(4))...\(suffix(4))"
    }
}
