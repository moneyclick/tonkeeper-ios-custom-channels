@testable import App
import Foundation
@testable import KeeperCore
import TKLocalize
import TonSwift
import XCTest

final class MultichainHistoryViewModelTests: XCTestCase {
    @MainActor
    func test_viewDidLoad_loadsFirstPageForAllNetworksAndAllTypes() async throws {
        let service = MultichainServiceSpy()
        await service.setActivityPlans([
            .success(page(activities: [activity(id: "all-1")], nextCursor: nil)),
        ])
        let viewModel = makeViewModel(multichainService: service)

        viewModel.viewDidLoad()

        await waitUntil {
            await MainActor.run {
                self.currentActivities(in: viewModel.currentQueryViewModel).count == 1
            }
        }

        let requests = await service.activityRequests()
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.walletId, "wallet")
        XCTAssertEqual(request.limit, 30)
        XCTAssertNil(request.cursor)
        XCTAssertNil(request.chain)
        XCTAssertNil(request.activityType)
        XCTAssertEqual(currentActivities(in: viewModel.currentQueryViewModel).map(\.txIds), [["all-1"]])
        XCTAssertEqual(currentItems(in: viewModel.currentQueryViewModel).map(\.id), currentActivities(in: viewModel.currentQueryViewModel))
        XCTAssertTrue(
            try viewModel.isTypeFilterActionBarVisible(
                for: XCTUnwrap(viewModel.currentQueryViewModel)
            )
        )
    }

    @MainActor
    func test_contentViewModel_keepsIndependentInstancesForNetworkAndTypeCategories() {
        let service = MultichainServiceSpy()
        let viewModel = makeViewModel(multichainService: service)

        let allCategory = MultichainHistoryCategory(
            chainFilter: .all,
            typeFilter: .all
        )
        let ethSendCategory = MultichainHistoryCategory(
            chainFilter: .chain(.eth),
            typeFilter: .send
        )

        let allViewModel = viewModel.contentViewModel(for: allCategory)
        let ethSendViewModel = viewModel.contentViewModel(for: ethSendCategory)

        XCTAssertTrue(viewModel.contentViewModel(for: allCategory) === allViewModel)
        XCTAssertTrue(viewModel.contentViewModel(for: ethSendCategory) === ethSendViewModel)
        XCTAssertFalse(allViewModel === ethSendViewModel)
    }

    @MainActor
    func test_typeFilterItems_exposeAllSentAndReceivedFilters() {
        let service = MultichainServiceSpy()
        let viewModel = makeViewModel(multichainService: service)

        XCTAssertEqual(
            viewModel.typeFilterItems.map(\.id),
            [.all, .send, .receive]
        )
    }

    @MainActor
    func test_typeFilterActionBarVisibility_hidesAllFilterOnlyWhenCurrentListIsEmpty() async throws {
        let service = MultichainServiceSpy()
        await service.setActivityPlans([
            .success(page(activities: [], nextCursor: nil)),
            .success(page(activities: [], nextCursor: nil)),
        ])
        let viewModel = makeViewModel(multichainService: service)

        viewModel.viewDidLoad()

        await waitUntil {
            await MainActor.run {
                viewModel.currentQueryViewModel?.presentation.placeholder == .empty
            }
        }

        let allQueryViewModel = try XCTUnwrap(viewModel.currentQueryViewModel)
        XCTAssertFalse(viewModel.isTypeFilterActionBarVisible(for: allQueryViewModel))

        viewModel.selectTypeFilter(.send)

        let sendQueryViewModel = try XCTUnwrap(viewModel.currentQueryViewModel)
        XCTAssertTrue(viewModel.isTypeFilterActionBarVisible(for: sendQueryViewModel))
    }

    @MainActor
    func test_addFundsAction_isPassedToQueryViewModel() {
        let service = MultichainServiceSpy()
        var didAddFunds = false
        let viewModel = makeViewModel(
            multichainService: service,
            onAddFunds: {
                didAddFunds = true
            }
        )

        let queryViewModel = viewModel.contentViewModel(
            for: MultichainHistoryCategory(
                chainFilter: .all,
                typeFilter: .all
            )
        )
        queryViewModel.addFunds()

        XCTAssertTrue(didAddFunds)
    }

    @MainActor
    func test_categoryViewModel_mapsNetworkAndTypeToAPIRequest() async throws {
        let service = MultichainServiceSpy()
        await service.setActivityPlans([
            .success(page(activities: [activity(id: "eth-send")], nextCursor: nil)),
        ])
        let viewModel = makeViewModel(multichainService: service)
        let category = MultichainHistoryCategory(
            chainFilter: .chain(.eth),
            typeFilter: .send
        )
        let queryViewModel = viewModel.contentViewModel(for: category)

        queryViewModel.appeared()

        await waitUntil {
            await service.activityRequests().count == 1
        }

        let requests = await service.activityRequests()
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.chain, .eth)
        XCTAssertEqual(request.activityType, .send)
    }

    @MainActor
    func test_loadNextPage_mergesActivitiesAndFiltersDuplicateValuesKeepingFirstOccurrence() async {
        let first = activity(id: "first", amount: "1")
        let duplicate = activity(id: "duplicate", amount: "2")
        let next = activity(id: "next", amount: "3")
        let service = MultichainServiceSpy()
        await service.setActivityPlans([
            .success(page(activities: [first, duplicate], nextCursor: "cursor-2")),
            .success(page(activities: [duplicate, next], nextCursor: nil)),
        ])
        let queryViewModel = makeQueryViewModel(multichainService: service)

        queryViewModel.appeared()
        await waitUntil {
            await MainActor.run {
                self.currentActivities(in: queryViewModel).count == 2
            }
        }

        guard let lastItem = currentItems(in: queryViewModel).last else {
            return XCTFail("Expected loaded item")
        }
        queryViewModel.loadNextPageIfNeeded(currentItem: lastItem)

        await waitUntil {
            await MainActor.run {
                self.currentActivities(in: queryViewModel).count == 3
            }
        }

        let requests = await service.activityRequests()
        XCTAssertEqual(requests.map(\.cursor), [nil, "cursor-2"])
        XCTAssertEqual(
            currentActivities(in: queryViewModel).map(\.txIds),
            [["first"], ["duplicate"], ["next"]]
        )
    }

    @MainActor
    func test_loadNextPageIfNeeded_ignoresRepeatedTriggerWhilePaginationIsRunning() async {
        let service = MultichainServiceSpy()
        await service.setActivityPlans([
            .success(
                page(
                    activities: (1 ... 6).map { activity(id: "\($0)") },
                    nextCursor: "cursor-2"
                )
            ),
            .success(
                page(
                    activities: [activity(id: "7")],
                    nextCursor: nil
                ),
                delayNanoseconds: 500_000_000
            ),
        ])
        let queryViewModel = makeQueryViewModel(multichainService: service)

        queryViewModel.appeared()
        await waitUntil {
            await MainActor.run {
                self.currentItems(in: queryViewModel).count == 6
            }
        }

        guard let lastItem = currentItems(in: queryViewModel).last else {
            return XCTFail("Expected loaded item")
        }
        queryViewModel.loadNextPageIfNeeded(currentItem: lastItem)
        queryViewModel.loadNextPageIfNeeded(currentItem: lastItem)

        try? await Task.sleep(nanoseconds: 50_000_000)
        let requests = await service.activityRequests()
        XCTAssertEqual(requests.count, 2)

        await waitUntil {
            await MainActor.run {
                self.currentItems(in: queryViewModel).count == 7
            }
        }
    }

    @MainActor
    func test_refreshFailure_keepsPreviouslyLoadedActivities() async {
        let loaded = activity(id: "loaded")
        let service = MultichainServiceSpy()
        await service.setActivityPlans([
            .success(page(activities: [loaded], nextCursor: nil)),
            .failure(.connectionError),
        ])
        let queryViewModel = makeQueryViewModel(multichainService: service)

        queryViewModel.appeared()
        await waitUntil {
            await MainActor.run {
                self.currentActivities(in: queryViewModel) == [loaded]
            }
        }

        await queryViewModel.refresh()

        XCTAssertEqual(currentActivities(in: queryViewModel), [loaded])
        XCTAssertEqual(currentErrorMessage(in: queryViewModel), TKLocales.ConnectionStatus.noInternet)
    }

    @MainActor
    func test_apiErrorWithoutMessage_usesBaseErrorPlaceholder() async {
        let service = MultichainServiceSpy()
        await service.setActivityPlans([
            .failure(.apiError(message: nil)),
        ])
        let queryViewModel = makeQueryViewModel(multichainService: service)

        queryViewModel.appeared()

        await waitUntil {
            await MainActor.run {
                if case .failed = queryViewModel.state {
                    return true
                }
                return false
            }
        }

        XCTAssertNil(currentErrorMessage(in: queryViewModel))
        XCTAssertEqual(queryViewModel.presentation.placeholder, .some(.error(nil)))
    }

    @MainActor
    func test_presentationGroupsActivitiesByRelativeDate() async {
        let currentDate = makeDate(year: 2026, month: 4, day: 29, hour: 12)
        let todayActivity = activity(
            id: "today",
            blockTime: makeDate(year: 2026, month: 4, day: 29, hour: 10)
        )
        let yesterdayActivity = activity(
            id: "yesterday",
            blockTime: makeDate(year: 2026, month: 4, day: 28, hour: 10)
        )
        let service = MultichainServiceSpy()
        await service.setActivityPlans([
            .success(page(activities: [todayActivity, yesterdayActivity], nextCursor: nil)),
        ])
        let queryViewModel = makeQueryViewModel(
            multichainService: service,
            currentDateProvider: { currentDate }
        )

        queryViewModel.appeared()
        await waitUntil {
            await MainActor.run {
                self.currentItems(in: queryViewModel).count == 2
            }
        }

        XCTAssertEqual(
            queryViewModel.presentation.sections.map(\.title),
            [TKLocales.Dates.today, TKLocales.Dates.yesterday]
        )
        XCTAssertEqual(
            queryViewModel.presentation.sections.map { $0.items.map(\.activity.txIds) },
            [[["today"]], [["yesterday"]]]
        )
    }

    @MainActor
    func test_presentationGroupsCurrentMonthByDayAndPastMonthsByMonth() async {
        let currentDate = makeDate(year: 2026, month: 4, day: 29, hour: 12)
        let currentMonthDay = activity(
            id: "april-27",
            blockTime: makeDate(year: 2026, month: 4, day: 27, hour: 10)
        )
        let currentMonthAnotherDay = activity(
            id: "april-15",
            blockTime: makeDate(year: 2026, month: 4, day: 15, hour: 10)
        )
        let pastMonthFirstDay = activity(
            id: "march-15",
            blockTime: makeDate(year: 2026, month: 3, day: 15, hour: 10)
        )
        let pastMonthSecondDay = activity(
            id: "march-10",
            blockTime: makeDate(year: 2026, month: 3, day: 10, hour: 10)
        )
        let pastYearFirstDay = activity(
            id: "december-31",
            blockTime: makeDate(year: 2025, month: 12, day: 31, hour: 10)
        )
        let pastYearSecondDay = activity(
            id: "december-1",
            blockTime: makeDate(year: 2025, month: 12, day: 1, hour: 10)
        )
        let service = MultichainServiceSpy()
        await service.setActivityPlans([
            .success(
                page(
                    activities: [
                        currentMonthDay,
                        currentMonthAnotherDay,
                        pastMonthFirstDay,
                        pastMonthSecondDay,
                        pastYearFirstDay,
                        pastYearSecondDay,
                    ],
                    nextCursor: nil
                )
            ),
        ])
        let queryViewModel = makeQueryViewModel(
            multichainService: service,
            currentDateProvider: { currentDate }
        )

        queryViewModel.appeared()
        await waitUntil {
            await MainActor.run {
                self.currentItems(in: queryViewModel).count == 6
            }
        }

        XCTAssertEqual(
            queryViewModel.presentation.sections.map(\.title),
            ["27 April", "15 April", "March", "December 2025"]
        )
        XCTAssertEqual(
            queryViewModel.presentation.sections.map { $0.items.map(\.activity.txIds) },
            [
                [["april-27"]],
                [["april-15"]],
                [["march-15"], ["march-10"]],
                [["december-31"], ["december-1"]],
            ]
        )
    }
}

private extension MultichainHistoryViewModelTests {
    @MainActor
    func makeViewModel(
        multichainService: MultichainService,
        currentDateProvider: @escaping () -> Date = Date.init,
        onAddFunds: @escaping () -> Void = {}
    ) -> MultichainHistoryViewModelImplementation {
        MultichainHistoryViewModelImplementation(
            wallet: makeWallet(),
            multichainService: multichainService,
            amountFormatter: makeAmountFormatter(),
            dateFormatter: makeDateFormatter(),
            currentDateProvider: currentDateProvider,
            chainImageProvider: { _ in nil },
            onAddFunds: onAddFunds
        )
    }

    @MainActor
    func makeQueryViewModel(
        multichainService: MultichainService,
        category: MultichainHistoryCategory = .init(chainFilter: .all, typeFilter: .all),
        currentDateProvider: @escaping () -> Date = Date.init
    ) -> MultichainHistoryQueryViewModel {
        MultichainHistoryQueryViewModel(
            walletId: "wallet",
            category: category,
            multichainService: multichainService,
            amountFormatter: makeAmountFormatter(),
            dateFormatter: makeDateFormatter(),
            currentDateProvider: currentDateProvider
        )
    }

    func makeWallet() -> Wallet {
        let publicKey = TonSwift.PublicKey(data: Data(repeating: 1, count: 32))
        return Wallet(
            id: "wallet",
            identity: WalletIdentity(network: .mainnet, kind: .Regular(publicKey, .v4R2)),
            metaData: WalletMetaData(label: "wallet", tintColor: .SteelGray, icon: .icon(.wallet)),
            setupSettings: WalletSetupSettings(),
            batterySettings: BatterySettings(),
            multichain: .addresses([
                MultichainWalletAddress(chain: .eth, address: "0xwallet"),
                MultichainWalletAddress(chain: .btc, address: "bc1wallet"),
            ])
        )
    }

    func makeAmountFormatter() -> AmountFormatter {
        var configuration = AmountFormatter.Configuration()
        configuration.locale = Locale(identifier: "en_US_POSIX")
        configuration.space = " "
        return AmountFormatter(configuration: configuration)
    }

    func makeDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter
    }

    func page(
        activities: [MultichainActivity],
        nextCursor: String?
    ) -> MultichainWalletActivitiesPage {
        MultichainWalletActivitiesPage(
            activities: activities,
            nextCursor: nextCursor
        )
    }

    func activity(
        id: String,
        activityType: MultichainActivityType = .send,
        amount: String = "1",
        blockTime: Date = Date(timeIntervalSince1970: 1_777_440_000)
    ) -> MultichainActivity {
        MultichainActivity(
            activityType: activityType,
            status: .confirmed,
            blockTime: blockTime,
            blockNumber: nil,
            fromChain: .eth,
            toChain: .eth,
            walletAddress: "0xwallet",
            direction: activityType == .receive ? .incoming : .outgoing,
            fromAddress: "0xfromaddress",
            toAddress: "0xtoaddress",
            outToken: asset(symbol: "ETH"),
            outAmount: amount,
            outAmountUsd: nil,
            inToken: asset(symbol: "ETH"),
            inAmount: amount,
            inAmountUsd: nil,
            feeToken: nil,
            feeAmount: nil,
            feeAmountUsd: nil,
            protocolName: nil,
            txIds: [id],
            isRead: nil
        )
    }

    func asset(symbol: String) -> MultichainAssetDetails {
        MultichainAssetDetails(
            assetId: "eth/mainnet/erc20/\(symbol.lowercased())",
            name: symbol,
            symbol: symbol,
            decimals: 18,
            image: ""
        )
    }

    @MainActor
    func currentItems(
        in queryViewModel: MultichainHistoryQueryViewModel?
    ) -> [MultichainHistoryActivityItem] {
        guard let queryViewModel else {
            return []
        }

        switch queryViewModel.state {
        case .idle:
            return []
        case let .loaded(rowData), let .failed(rowData, _), let .refreshing(rowData, _), let .loadingMore(rowData, _):
            return rowData.items
        }
    }

    @MainActor
    func currentActivities(
        in queryViewModel: MultichainHistoryQueryViewModel?
    ) -> [MultichainActivity] {
        currentItems(in: queryViewModel).map(\.activity)
    }

    @MainActor
    func currentErrorMessage(
        in queryViewModel: MultichainHistoryQueryViewModel
    ) -> String? {
        switch queryViewModel.state {
        case let .failed(_, errorMessage):
            return errorMessage
        case .idle, .refreshing, .loaded, .loadingMore:
            return nil
        }
    }

    func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(
            from: DateComponents(
                timeZone: TimeZone(secondsFromGMT: 0),
                year: year,
                month: month,
                day: day,
                hour: hour
            )
        )!
    }

    func waitUntil(
        timeout: TimeInterval = 2,
        intervalNanoseconds: UInt64 = 10_000_000,
        condition: @escaping () async -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if await condition() {
                return
            }

            try? await Task.sleep(nanoseconds: intervalNanoseconds)
        }

        XCTFail("Timed out waiting for condition")
    }
}

private actor MultichainServiceSpy: MultichainService {
    struct ActivityRequest: Equatable {
        let walletId: String
        let limit: Int?
        let cursor: String?
        let chain: MultichainChain?
        let activityType: MultichainActivityType?
    }

    struct Plan {
        let result: Result<MultichainWalletActivitiesPage, MultichainServiceError>
        let delayNanoseconds: UInt64

        static func success(
            _ page: MultichainWalletActivitiesPage,
            delayNanoseconds: UInt64 = 0
        ) -> Plan {
            Plan(
                result: .success(page),
                delayNanoseconds: delayNanoseconds
            )
        }

        static func failure(
            _ error: MultichainServiceError,
            delayNanoseconds: UInt64 = 0
        ) -> Plan {
            Plan(
                result: .failure(error),
                delayNanoseconds: delayNanoseconds
            )
        }
    }

    private var activityPlanQueue = [Plan]()
    private var recordedActivityRequests = [ActivityRequest]()

    func setActivityPlans(_ plans: [Plan]) {
        activityPlanQueue = plans
    }

    func activityRequests() -> [ActivityRequest] {
        recordedActivityRequests
    }

    func getWalletActivities(
        walletId: String,
        limit: Int?,
        cursor: String?,
        chain: MultichainChain?,
        activityType: MultichainActivityType?
    ) async throws(MultichainServiceError) -> MultichainWalletActivitiesPage {
        recordedActivityRequests.append(
            ActivityRequest(
                walletId: walletId,
                limit: limit,
                cursor: cursor,
                chain: chain,
                activityType: activityType
            )
        )

        guard !activityPlanQueue.isEmpty else {
            throw .apiError(message: "Missing activity plan")
        }

        let plan = activityPlanQueue.removeFirst()
        if plan.delayNanoseconds > 0 {
            do {
                try await Task.sleep(nanoseconds: plan.delayNanoseconds)
            } catch {
                throw .cancelled
            }
        }

        return try plan.result.get()
    }

    func healthcheck() async throws(MultichainServiceError) -> MultichainHealth {
        throw .apiError(message: "Unimplemented")
    }

    func getNodes(ifNoneMatch: String?) async throws(MultichainServiceError) -> MultichainNodesResponse {
        throw .apiError(message: "Unimplemented")
    }

    func searchAssets(
        currencies: [String],
        chain: MultichainChain?,
        search: String?,
        sort: MultichainAssetSearchSort,
        limit: Int?,
        cursor: String?
    ) async throws(MultichainServiceError) -> (assets: [MultichainAsset], nextCursor: String?) {
        throw .apiError(message: "Unimplemented")
    }

    func getWallet(walletId: String) async throws(MultichainServiceError) -> MultichainRegisteredWallet {
        throw .apiError(message: "Unimplemented")
    }

    func getWalletAssets(
        walletId: String,
        currencies: [String],
        chain: MultichainChain?,
        search: String?,
        availableOnly: Bool?,
        showHidden: Bool?,
        limit: Int?,
        cursor: String?
    ) async throws(MultichainServiceError) -> MultichainWalletAssetsPage {
        throw .apiError(message: "Unimplemented")
    }

    func saveWalletAssetsFilters(walletId: String, changes: [MultichainAssetFilterChange]) async throws(MultichainServiceError) {
        throw .apiError(message: "Unimplemented")
    }

    func registerWallet(walletId: String, addresses: [MultichainWalletAddress]) async throws(MultichainServiceError) -> MultichainRegisteredWallet {
        throw .apiError(message: "Unimplemented")
    }

    func broadcastTx(chain: MultichainChain, signedTransaction: Data) async throws(MultichainServiceError) -> MultichainBroadcastResult {
        throw .apiError(message: "Unimplemented")
    }

    func getFees(chain: MultichainChain) async throws(MultichainServiceError) -> MultichainFeeEstimate {
        throw .apiError(message: "Unimplemented")
    }
}
