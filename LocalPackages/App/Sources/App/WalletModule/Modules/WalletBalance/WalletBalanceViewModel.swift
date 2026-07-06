import Foundation
import KeeperCore
import TKCore
import TKLocalize
import TKUIKit
import TonSwift
import UIKit

protocol WalletBalanceModuleOutput: AnyObject {
    var didSelectTon: ((Wallet) -> Void)? { get set }
    var didSelectJetton: ((Wallet, JettonItem, Bool) -> Void)? { get set }
    var didSelectTronUSDT: ((Wallet) -> Void)? { get set }
    var didSelectEthena: ((Wallet) -> Void)? { get set }
    var didSelectStakingItem: ((
        _ wallet: Wallet,
        _ stakingPoolInfo: StackingPoolInfo,
        _ accountStakingInfo: AccountStackingInfo
    ) -> Void)? { get set }
    var didSelectCollectStakingItem: ((
        _ wallet: Wallet,
        _ stakingPoolInfo: StackingPoolInfo,
        _ accountStakingInfo: AccountStackingInfo
    ) -> Void)? { get set }

    var didTapDeposit: ((_ wallet: Wallet) -> Void)? { get set }
    var didTapWithdraw: ((Wallet) -> Void)? { get set }
    var didTapSwap: ((Wallet) -> Void)? { get set }
    var didTapStake: ((Wallet) -> Void)? { get set }

    var didTapBackup: ((Wallet) -> Void)? { get set }
    var didTapBattery: ((Wallet) -> Void)? { get set }

    var didTapManage: ((Wallet) -> Void)? { get set }
    var didTapOpenCryptoAssets: (() -> Void)? { get set }

    var didRequirePasscode: (() async -> String?)? { get set }

    var homeBannersViewModel: WalletBalanceHomeBannersViewModel { get }
}

protocol WalletBalanceModuleInput: AnyObject {}

protocol WalletBalanceViewModel: AnyObject {
    var didUpdateSnapshot: ((_ snapshot: WalletBalance.Snapshot, _ isAnimated: Bool) -> Void)? { get set }

    var didUpdateItems: (([WalletBalance.ListItem: WalletBalanceListCell.Configuration]) -> Void)? { get set }

    var didChangeWallet: (() -> Void)? { get set }
    var didUpdateHeader: ((BalanceHeaderView.Model) -> Void)? { get set }
    var didCopy: ((ToastPresenter.Configuration) -> Void)? { get set }

    func reloadData()

    @MainActor
    func viewDidLoad()
    @MainActor
    func getListItemCellConfiguration(identifier: String) -> WalletBalanceListCell.Configuration?
    @MainActor
    func getNotificationItemCellConfiguration(identifier: String) -> NotificationBannerCell.Configuration?

    var shouldShowBannersSection: Bool { get }

    var homeBannersViewModel: WalletBalanceHomeBannersViewModel { get }

    @MainActor
    func tapCryptoAssetsManage()

    @MainActor
    func tapCryptoAssetsOpen()
}

struct WalletBalanceListModel: @unchecked Sendable {
    let snapshot: WalletBalance.Snapshot
    let listItemsConfigurations: [String: WalletBalanceListCell.Configuration]
    let notificationItemsConfigurations: [String: NotificationBannerCell.Configuration]
}

final class WalletBalanceViewModelImplementation:
    @unchecked Sendable,
    WalletBalanceViewModel,
    WalletBalanceModuleOutput,
    WalletBalanceModuleInput
{
    // MARK: - WalletBalanceModuleOutput

    var didUpdateSnapshot: ((_ snapshot: WalletBalance.Snapshot, _ isAnimated: Bool) -> Void)?
    var didUpdateItems: (([WalletBalance.ListItem: WalletBalanceListCell.Configuration]) -> Void)?

    var didSelectTon: ((Wallet) -> Void)?
    var didSelectJetton: ((Wallet, JettonItem, Bool) -> Void)?
    var didSelectTronUSDT: ((Wallet) -> Void)?
    var didSelectEthena: ((Wallet) -> Void)?
    var didSelectStakingItem: ((
        _ wallet: Wallet,
        _ stakingPoolInfo: StackingPoolInfo,
        _ accountStakingInfo: AccountStackingInfo
    ) -> Void)?
    var didSelectCollectStakingItem: ((
        _ wallet: Wallet,
        _ stakingPoolInfo: StackingPoolInfo,
        _ accountStakingInfo: AccountStackingInfo
    ) -> Void)?

    var didTapWithdraw: ((Wallet) -> Void)?
    var didTapDeposit: ((Wallet) -> Void)?
    var didTapSwap: ((Wallet) -> Void)?
    var didTapStake: ((Wallet) -> Void)?

    var didTapBackup: ((Wallet) -> Void)?
    var didTapBattery: ((Wallet) -> Void)?

    var didTapManage: ((Wallet) -> Void)?
    var didTapOpenCryptoAssets: (() -> Void)?

    var didRequirePasscode: (() async -> String?)?

    // MARK: - WalletBalanceViewModel

    var didChangeWallet: (() -> Void)?
    var didUpdateHeader: ((BalanceHeaderView.Model) -> Void)?
    var didCopy: ((ToastPresenter.Configuration) -> Void)?
    private var loadBalanceTrace: Trace?

    func viewDidLoad() {
        let balanceItems = try? balanceListModel.getItems()
        let setupState = setupModel.getState()
        let notifications = Array(notificationStore.getState())

        syncQueue.async {
            self.balanceListItems = balanceItems
            self.setupState = setupState
            self.notifications = notifications
        }
        setupObservations()

        let listModel = createWalletBalanceListModel(
            balanceListItems: balanceItems,
            setupState: setupState,
            notifications: notifications
        )
        self.listModel = listModel
        didUpdateSnapshot?(listModel.snapshot, false)

        if let totalBalanceModelState = try? totalBalanceModel.getState() {
            let model = syncQueue.sync {
                createHeaderModel(totalBalanceModelState: totalBalanceModelState)
            }
            didUpdateHeader?(model)
        }
    }

    func reloadData() {
        balanceLoader.loadActiveWalletBalance()
    }

    private func refreshHeaderLocked() {
        guard let totalBalanceModelState = try? self.totalBalanceModel.getState() else { return }
        let model = self.createHeaderModel(totalBalanceModelState: totalBalanceModelState)
        DispatchQueue.main.async {
            self.didUpdateHeader?(model)
        }
    }

    func getListItemCellConfiguration(identifier: String) -> WalletBalanceListCell.Configuration? {
        listModel.listItemsConfigurations[identifier]
    }

    func getNotificationItemCellConfiguration(identifier: String) -> NotificationBannerCell.Configuration? {
        listModel.notificationItemsConfigurations[identifier]
    }

    // MARK: - State

    private let syncQueue = DispatchQueue(label: "SyncQueue")

    @MainActor
    private var listModel = WalletBalanceListModel(
        snapshot: WalletBalance.Snapshot(),
        listItemsConfigurations: [:],
        notificationItemsConfigurations: [:]
    )
    private var balanceListItems: WalletBalanceBalanceModel.BalanceListItems?
    private var setupState: WalletBalanceSetupModel.State?
    private var notifications = [NotificationModel]()
    private var stakingUpdateTimer: DispatchSourceTimer?

    // MARK: - Mapper

    // MARK: - Dependencies

    private let balanceListModel: WalletBalanceBalanceModel
    private let balanceLoader: BalanceLoader
    private let setupModel: WalletBalanceSetupModel
    private let totalBalanceModel: WalletTotalBalanceModel
    private let walletsStore: WalletsStore
    private let notificationStore: InternalNotificationsStore
    private let configuration: Configuration
    private let appSettingsStore: AppSettingsStore
    private let listMapper: WalletBalanceListMapper
    private let headerMapper: WalletBalanceHeaderMapper
    private let urlOpener: URLOpener
    private let appSettings: AppSettings
    private let tooltipsService: TooltipsService
    let homeBannersViewModel: WalletBalanceHomeBannersViewModel

    private var isBannersSectionVisible = false

    var shouldShowBannersSection: Bool {
        isBannersSectionVisible
    }

    init(
        balanceListModel: WalletBalanceBalanceModel,
        balanceLoader: BalanceLoader,
        setupModel: WalletBalanceSetupModel,
        totalBalanceModel: WalletTotalBalanceModel,
        walletsStore: WalletsStore,
        notificationStore: InternalNotificationsStore,
        configuration: Configuration,
        appSettingsStore: AppSettingsStore,
        listMapper: WalletBalanceListMapper,
        headerMapper: WalletBalanceHeaderMapper,
        urlOpener: URLOpener,
        appSettings: AppSettings,
        tooltipsService: TooltipsService,
        homeBannersViewModel: WalletBalanceHomeBannersViewModel
    ) {
        self.balanceListModel = balanceListModel
        self.balanceLoader = balanceLoader
        self.setupModel = setupModel
        self.totalBalanceModel = totalBalanceModel
        self.walletsStore = walletsStore
        self.notificationStore = notificationStore
        self.configuration = configuration
        self.appSettingsStore = appSettingsStore
        self.listMapper = listMapper
        self.headerMapper = headerMapper
        self.urlOpener = urlOpener
        self.appSettings = appSettings
        self.tooltipsService = tooltipsService
        self.homeBannersViewModel = homeBannersViewModel
    }

    @MainActor
    func bindBannersSectionVisibility() {
        homeBannersViewModel.onSectionVisibilityChanged = { [weak self] isVisible in
            self?.didUpdateBannersSectionVisibility(isVisible: isVisible)
        }
        let isVisible = homeBannersViewModel.isSectionVisible
        syncQueue.sync { [weak self] in
            self?.isBannersSectionVisible = isVisible
        }
    }

    @MainActor
    func tapCryptoAssetsManage() {
        guard let balanceListItems,
              balanceListItems.canManage
        else {
            return
        }
        didTapManage?(balanceListItems.wallet)
    }

    @MainActor
    func tapCryptoAssetsOpen() {
        didTapOpenCryptoAssets?()
    }

    private func didUpdateBannersSectionVisibility(isVisible: Bool) {
        syncQueue.async { [weak self] in
            self?.applyBannersSectionVisibility(isVisible: isVisible)
        }
    }

    private func applyBannersSectionVisibility(isVisible: Bool) {
        let wasShowing = shouldShowBannersSection
        isBannersSectionVisible = isVisible
        let isShowing = shouldShowBannersSection
        guard wasShowing != isShowing else { return }

        let listModel = createWalletBalanceListModel(
            balanceListItems: balanceListItems,
            setupState: setupState,
            notifications: notifications
        )
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.listModel = listModel
            self.didUpdateSnapshot?(listModel.snapshot, !isShowing)
        }
    }

    private func setupObservations() {
        totalBalanceModel.didUpdateState = { [weak self] state in
            self?.didUpdateTotalBalanceState(state)
        }
        balanceListModel.didUpdateItems = { [weak self] items in
            guard let self else { return }
            syncQueue.async {
                self.didUpdateBalanceItems(balanceListItems: items)
            }
        }
        setupModel.didUpdateState = { [weak self] state in
            guard let self else { return }
            syncQueue.async {
                self.didUpdateSetupState(setupState: state)
            }
        }
        walletsStore.addObserver(self) { _, event in
            switch event {
            case .didChangeActiveWallet:
                DispatchQueue.main.async {
                    self.didChangeWallet?()
                }
            default:
                break
            }
        }
        notificationStore.addObserver(self) { observer, event in
            switch event {
            case let .didUpdateNotifications(notifications):
                observer.syncQueue.async {
                    observer.didUpdateNotifications(notifications: notifications)
                }
            }
        }

        configuration.addUpdateObserver(self) { observer in
            observer.syncQueue.async {
                guard let totalBalanceModelState = try? observer.totalBalanceModel.getState() else {
                    return
                }
                let model = observer.createHeaderModel(totalBalanceModelState: totalBalanceModelState)
                DispatchQueue.main.async {
                    observer.didUpdateHeader?(model)
                }
            }
        }
    }

    private func didUpdateBalanceItems(balanceListItems: WalletBalanceBalanceModel.BalanceListItems) {
        self.balanceListItems = balanceListItems
        let listModel = self.createWalletBalanceListModel(
            balanceListItems: balanceListItems,
            setupState: setupState,
            notifications: notifications
        )
        DispatchQueue.main.async {
            self.listModel = listModel
            self.didUpdateSnapshot?(listModel.snapshot, false)
        }
        self.stopStakingItemsUpdateTimer()
        self.startStakingItemsUpdateTimer(
            wallet: balanceListItems.wallet,
            stakingItems: balanceListItems.items.getStakingItems()
        )
    }

    private func didUpdateSetupState(setupState: WalletBalanceSetupModel.State?) {
        let hadSetupSection = self.setupState != nil
        self.setupState = setupState
        let listModel = self.createWalletBalanceListModel(
            balanceListItems: balanceListItems,
            setupState: setupState,
            notifications: notifications
        )
        let animateRemoval = hadSetupSection && setupState == nil
        DispatchQueue.main.async {
            self.listModel = listModel
            self.didUpdateSnapshot?(listModel.snapshot, animateRemoval)
        }
    }

    private func didUpdateNotifications(notifications: [NotificationModel]) {
        self.notifications = notifications
        let listModel = self.createWalletBalanceListModel(
            balanceListItems: balanceListItems,
            setupState: setupState,
            notifications: notifications
        )
        DispatchQueue.main.async {
            self.listModel = listModel
            self.didUpdateSnapshot?(listModel.snapshot, false)
        }
    }

    private func createWalletBalanceListModel(
        balanceListItems: WalletBalanceBalanceModel.BalanceListItems?,
        setupState: WalletBalanceSetupModel.State?,
        notifications: [NotificationModel]
    ) -> WalletBalanceListModel {
        var snapshot = WalletBalance.Snapshot()
        var listItemsConfigurations = [String: WalletBalanceListCell.Configuration]()
        var notificationItemsConfigurations = [String: NotificationBannerCell.Configuration]()

        if !notifications.isEmpty {
            let (section, cellConfigurations) = createNotificationsSection(notifications: notifications)
            notificationItemsConfigurations.merge(cellConfigurations) { $1 }
            snapshot.appendSections([.notifications(section)])
            snapshot.appendItems(section.items.map { .notificationItem($0) }, toSection: .notifications(section))
        }

        snapshot.appendSections([.balanceHeader])
        snapshot.appendItems([.balanceHeader], toSection: .balanceHeader)

        if shouldShowBannersSection {
            snapshot.appendSections([.banners])
            snapshot.appendItems([.banners], toSection: .banners)
        }

        if let setupState {
            let (section, cellConfigurations) = createSetupSection(setupState: setupState)
            listItemsConfigurations.merge(cellConfigurations) { $1 }
            snapshot.appendSections([.setup(section)])
            snapshot.appendItems(section.items.map { .listItem($0) }, toSection: .setup(section))
        }

        if let balanceListItems {
            snapshot.appendSections([.cryptoAssetsHeader(canManage: balanceListItems.canManage)])
            snapshot.appendItems([.cryptoAssetsHeader], toSection: .cryptoAssetsHeader(canManage: balanceListItems.canManage))

            let (section, cellConfigurations) = createBalanceSection(balanceListItems: balanceListItems)
            listItemsConfigurations.merge(cellConfigurations) { $1 }
            snapshot.appendSections([.balance(section)])
            snapshot.appendItems(section.items.map { .listItem($0) }, toSection: .balance(section))
        }

        if #available(iOS 15.0, *) {
            snapshot.reconfigureItems(snapshot.itemIdentifiers)
        } else {
            snapshot.reloadItems(snapshot.itemIdentifiers)
        }

        return WalletBalanceListModel(
            snapshot: snapshot,
            listItemsConfigurations: listItemsConfigurations,
            notificationItemsConfigurations: notificationItemsConfigurations
        )
    }

    private func createBalanceSection(
        balanceListItems: WalletBalanceBalanceModel.BalanceListItems
    ) -> (section: WalletBalance.BalanceItemsSection, cellConfigurations: [String: WalletBalanceListCell.Configuration]) {
        var cellConfigurations = [String: WalletBalanceListCell.Configuration]()
        var sectionItems = [WalletBalance.ListItem]()
        for balanceListItem in balanceListItems.items {
            switch balanceListItem.balanceItem {
            case let .ton(item):
                let cellConfiguration = listMapper.mapTonItem(
                    item,
                    wallet: balanceListItems.wallet,
                    isSecure: balanceListItems.isSecure,
                    isPinned: balanceListItem.isPinned
                )
                let sectionItem = WalletBalance.ListItem(
                    identifier: item.id
                ) { [weak self] in
                    self?.didSelectTon?(balanceListItems.wallet)
                }
                cellConfigurations[item.id] = cellConfiguration
                sectionItems.append(sectionItem)
            case let .jetton(item):
                let isNetworkBadgeVisible = item.jetton.jettonInfo.isTonUSDT && balanceListItems.wallet.isTronTurnOn
                let cellConfiguration = listMapper.mapJettonItem(
                    item,
                    isSecure: balanceListItems.isSecure,
                    isPinned: balanceListItem.isPinned,
                    isNetworkBadgeVisible: isNetworkBadgeVisible
                )
                let sectionItem = WalletBalance.ListItem(
                    identifier: item.id
                ) { [weak self] in
                    self?.didSelectJetton?(balanceListItems.wallet, item.jetton, !item.price.isZero)
                }
                cellConfigurations[item.id] = cellConfiguration
                sectionItems.append(sectionItem)
            case let .staking(item):
                let cellConfiguration = listMapper.mapStakingItem(
                    item,
                    isSecure: balanceListItems.isSecure,
                    isPinned: balanceListItem.isPinned,
                    isStakingEnable: balanceListItems.wallet.isStakeEnable,
                    stakingCollectHandler: { [weak self] in
                        guard let self,
                              let poolInfo = item.poolInfo else { return }
                        self.didSelectCollectStakingItem?(balanceListItems.wallet, poolInfo, item.info)
                    }
                )
                let sectionItem = WalletBalance.ListItem(
                    identifier: item.id
                ) { [weak self] in
                    guard let self,
                          let poolInfo = item.poolInfo else { return }
                    self.didSelectStakingItem?(balanceListItems.wallet, poolInfo, item.info)
                }
                cellConfigurations[item.id] = cellConfiguration
                sectionItems.append(sectionItem)
            case let .tronUSDT(item):
                if
                    configuration.flag(\.tronDisabled, network: balanceListItems.wallet.network),
                    item.amount.isZero
                { continue }

                let cellConfiguration = listMapper.mapTronUSDTItem(
                    item,
                    isSecure: balanceListItems.isSecure,
                    isPinned: balanceListItem.isPinned
                )
                let sectionItem = WalletBalance.ListItem(
                    identifier: item.id
                ) { [weak self] in
                    self?.didSelectTronUSDT?(balanceListItems.wallet)
                }
                cellConfigurations[item.id] = cellConfiguration
                sectionItems.append(sectionItem)
            case let .ethena(item):
                let identifier = "ethena_\(item.id)"
                let cellConfiguration = listMapper.mapEthenaItem(
                    item,
                    isSecure: balanceListItems.isSecure,
                    isPinned: balanceListItem.isPinned
                )

                var accessory: TKListItemAccessory?
                if item.amount.isZero {
                    accessory = .button(
                        TKListItemButtonAccessoryView.Configuration(
                            title: TKLocales.Actions.open,
                            category: .tertiary,
                            action: { [weak self] in
                                self?.didSelectEthena?(balanceListItems.wallet)
                            }
                        )
                    )
                }

                let sectionItem = WalletBalance.ListItem(
                    identifier: identifier,
                    accessory: accessory
                ) { [weak self] in
                    self?.didSelectEthena?(balanceListItems.wallet)
                }
                cellConfigurations[identifier] = cellConfiguration
                sectionItems.append(sectionItem)
            }
        }

        let section = WalletBalance.BalanceItemsSection(items: sectionItems)
        return (section, cellConfigurations)
    }

    private func createSetupSection(
        setupState: WalletBalanceSetupModel.State
    ) -> (section: WalletBalance.SetupSection, cellConfigurations: [String: WalletBalanceListCell.Configuration]) {
        var cellConfigurations = [String: WalletBalanceListCell.Configuration]()
        var sectionItems = [WalletBalance.ListItem]()

        for item in setupState.items {
            switch item {
            case .notifications:
                let action: (Bool) -> Void = { [weak self] _ in
                    guard let self else { return }
                    Task {
                        await self.setupModel.turnOnNotifications()
                    }
                }

                let configuration = self.listMapper.createNotificationsConfiguration()
                let notificationsItem = WalletBalance.ListItem(
                    identifier: item.rawValue,
                    accessory: .switch(
                        TKListItemSwitchAccessoryView.Configuration(
                            isOn: false,
                            action: action
                        )
                    ),
                    onSelection: {
                        action(true)
                    }
                )
                cellConfigurations[item.rawValue] = configuration
                sectionItems.append(notificationsItem)
            case .backup:
                let backupConfiguration = self.listMapper.createBackupConfiguration()
                let backupItem = WalletBalance.ListItem(
                    identifier: item.rawValue,
                    accessory: .chevron,
                    onSelection: { [weak self] in
                        guard let self else { return }
                        Task {
                            await MainActor.run {
                                self.didTapBackup?(setupState.wallet)
                            }
                        }
                    }
                )
                cellConfigurations[item.rawValue] = backupConfiguration
                sectionItems.append(backupItem)
            case .biometry:
                let action: (Bool) -> Void = { [weak self] isOn in
                    guard let self else { return }
                    Task {
                        do {
                            if isOn {
                                guard let passcode = await self.didRequirePasscode?() else {
                                    self.syncQueue.async {
                                        self.didUpdateSetupState(setupState: setupState)
                                    }
                                    return
                                }
                                try await self.setupModel.turnOnBiometry(passcode: passcode)
                            } else {
                                try await self.setupModel.turnOffBiometry()
                            }
                        } catch {
                            await MainActor.run {
                                self.didCopy?(.failed)
                            }
                            self.syncQueue.async {
                                self.didUpdateSetupState(setupState: setupState)
                            }
                        }
                    }
                }

                let biometryConfiguration = self.listMapper.createBiometryConfiguration()
                let biometryItem = WalletBalance.ListItem(
                    identifier: item.rawValue,
                    accessory: .switch(
                        TKListItemSwitchAccessoryView.Configuration(
                            isOn: false,
                            action: action
                        )
                    ),
                    onSelection: {
                        action(true)
                    }
                )
                cellConfigurations[item.rawValue] = biometryConfiguration
                sectionItems.append(biometryItem)
            }
        }

        var headerButtonConfiguration: TKButton.Configuration?
        if setupState.isFinishEnable {
            headerButtonConfiguration = .actionButtonConfiguration(category: .secondary, size: .small)
            headerButtonConfiguration?.content = TKButton.Configuration.Content(title: .plainString(TKLocales.Actions.done))
            headerButtonConfiguration?.action = { [weak self] in
                self?.setupModel.finishSetup(for: setupState.wallet)
            }
        }

        let headerConfiguration = TKListCollectionViewButtonHeaderView.Configuration(
            identifier: .setupSectionHeaderIdentifier,
            title: TKLocales.FinishSetup.title,
            buttonConfiguration: headerButtonConfiguration
        )

        let section = WalletBalance.SetupSection(
            items: sectionItems,
            headerConfiguration: headerConfiguration
        )
        return (section, cellConfigurations)
    }

    private func createNotificationsSection(notifications: [NotificationModel])
        -> (section: WalletBalance.NotificationSection, cellConfigurations: [String: NotificationBannerCell.Configuration])
    {
        var cellConfigurations = [String: NotificationBannerCell.Configuration]()
        var items = [WalletBalance.NotificationItem]()
        for notification in notifications {
            let actionButton: NotificationBannerView.Model.ActionButton? = {
                guard let action = notification.action else {
                    return nil
                }

                let actionButtonAction: () -> Void
                switch action.type {
                case let .openLink(url):
                    actionButtonAction = { [weak self] in
                        guard let url else { return }
                        self?.urlOpener.open(url: url)
                    }
                }
                return NotificationBannerView.Model.ActionButton(title: action.label, action: actionButtonAction)
            }()
            let cellConfiguration = NotificationBannerCell.Configuration(
                bannerViewConfiguration: NotificationBannerView.Model(
                    title: notification.title,
                    caption: notification.caption,
                    appearance: {
                        switch notification.mode {
                        case .critical:
                            return .accentRed
                        case .warning:
                            return .accentYellow
                        }
                    }(),
                    actionButton: actionButton,
                    closeButton: NotificationBannerView.Model.CloseButton(
                        action: { [weak self] in
                            guard let self else { return }
                            Task {
                                await self.notificationStore.removeNotification(notification, persistant: true)
                            }
                        }
                    )
                )
            )
            let item = WalletBalance.NotificationItem(
                id: notification.id,
                cellConfiguration: cellConfiguration
            )

            cellConfigurations[notification.id] = cellConfiguration
            items.append(item)
        }

        let section = WalletBalance.NotificationSection(
            items: items
        )

        return (section, cellConfigurations)
    }

    private func startStakingItemsUpdateTimer(
        wallet: Wallet,
        stakingItems: [WalletBalanceBalanceModel.Item]
    ) {
        let queue = DispatchQueue(label: "WalletBalanceStakingItemsTimerQueue", qos: .background)
        let timer: DispatchSourceTimer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        timer.schedule(deadline: .now(), repeating: 1, leeway: .milliseconds(100))
        timer.resume()
        timer.setEventHandler(handler: { [weak self] in
            guard let self else { return }
            Task {
                await self.updateStakingItemsOnTimer(
                    wallet: wallet,
                    stakingItems: stakingItems
                )
            }
        })
        self.stakingUpdateTimer = timer
    }

    private func stopStakingItemsUpdateTimer() {
        self.stakingUpdateTimer?.cancel()
        self.stakingUpdateTimer = nil
    }

    func updateStakingItemsOnTimer(
        wallet: Wallet,
        stakingItems: [WalletBalanceBalanceModel.Item]
    ) async {
        let listModel = await self.listModel
        let isSecure = self.appSettingsStore.state.isSecureMode
        var listItemsConfigurations = listModel.listItemsConfigurations
        var items = [WalletBalance.ListItem: WalletBalanceListCell.Configuration]()

        for item in stakingItems {
            guard case let .staking(stakingItem) = item.balanceItem else { continue }
            let cellConfiguration = self.listMapper.mapStakingItem(
                stakingItem,
                isSecure: isSecure,
                isPinned: item.isPinned,
                isStakingEnable: wallet.isStakeEnable,
                stakingCollectHandler: { [weak self] in
                    guard let poolInfo = stakingItem.poolInfo else { return }
                    self?.didSelectCollectStakingItem?(wallet, poolInfo, stakingItem.info)
                }
            )
            listItemsConfigurations[stakingItem.id] = cellConfiguration

            let item = WalletBalance.ListItem(
                identifier: stakingItem.id
            ) { [weak self] in
                guard let self,
                      let poolInfo = stakingItem.poolInfo else { return }
                self.didSelectStakingItem?(wallet, poolInfo, stakingItem.info)
            }
            items[item] = cellConfiguration
        }

        let updatedListModel = WalletBalanceListModel(
            snapshot: listModel.snapshot,
            listItemsConfigurations: listItemsConfigurations,
            notificationItemsConfigurations: listModel.notificationItemsConfigurations
        )

        await MainActor.run { [items] in
            self.listModel = updatedListModel
            self.didUpdateItems?(items)
        }
    }

    func createHeaderModel(totalBalanceModelState: WalletTotalBalanceModel.State) -> BalanceHeaderView.Model {
        let addressButtonText: String = {
            if self.appSettings.addressCopyCount > 2 {
                totalBalanceModelState.address.toShort()
            } else {
                (totalBalanceModelState.wallet.kind == .watchonly ? TKLocales.BalanceHeader.address : TKLocales.BalanceHeader.yourAddress) + totalBalanceModelState.address.toShort()
            }
        }()

        let statusViewConfiguration: BalanceHeaderBalanceStatusView.Configuration = {
            let action = { [weak self] in
                guard let self else { return }
                self.didTapCopy(
                    address: totalBalanceModelState.address.toString(),
                    toastConfiguration: totalBalanceModelState.wallet.copyToastConfiguration()
                )
                self.appSettings.addressCopyCount += 1
                if self.appSettings.addressCopyCount <= 3 {
                    didUpdateTotalBalanceState(totalBalanceModelState)
                }
            }

            if let connectionStatusModel = self.createConnectionStatusModel(
                backgroundUpdateState: totalBalanceModelState.backgroundUpdateConnectionState,
                isLoading: totalBalanceModelState.isLoadingBalance
            ) {
                return BalanceHeaderBalanceStatusView.Configuration(
                    state: .connection(connectionStatusModel),
                    action: action
                )
            } else if let totalBalanceState = totalBalanceModelState.totalBalanceState, case let .previous(totalBalance) = totalBalanceState {
                return BalanceHeaderBalanceStatusView.Configuration(
                    state: .updated(TKLocales.ConnectionStatus.updatedAt(self.headerMapper.makeUpdatedDate(totalBalance.date))),
                    action: action
                )
            } else {
                return BalanceHeaderBalanceStatusView.Configuration(
                    state: .address(addressButtonText, tags: totalBalanceModelState.wallet.balanceTagConfigurations()),
                    action: action
                )
            }
        }()

        let headerModel = BalanceHeaderBalanceView.Model(
            amountViewConfiguration: createAmountViewConfiguration(state: totalBalanceModelState),
            statusViewConfiguration: statusViewConfiguration
        )

        return BalanceHeaderView.Model(
            balanceModel: headerModel,
            buttonsModel: self.createHeaderButtonsRedesignModel(wallet: totalBalanceModelState.wallet)
        )
    }

    func createAmountViewConfiguration(state: WalletTotalBalanceModel.State) -> BalanceHeaderBalanceAmountView.Configuration {
        let totalBalanceMapped = self.headerMapper.mapTotalBalance(totalBalance: state.totalBalanceState?.totalBalance)

        let backupWarningState = BalanceBackupWarningCheck().check(
            wallet: state.wallet,
            tonAmount: state.totalBalanceState?.totalBalance?.balance.tonItems.first?.amount ?? 0
        )
        let balanceColor: UIColor
        var backupButton: BalanceHeaderBalanceAmountView.Configuration.BackupButton?
        switch backupWarningState {
        case .error:
            balanceColor = .Accent.red
            backupButton = BalanceHeaderBalanceAmountView.Configuration.BackupButton(
                color: .Accent.red,
                action: { [weak self] in
                    self?.didTapBackup?(state.wallet)
                }
            )
        case .warning:
            balanceColor = .Accent.orange
            backupButton = BalanceHeaderBalanceAmountView.Configuration.BackupButton(
                color: .Accent.orange,
                action: { [weak self] in
                    self?.didTapBackup?(state.wallet)
                }
            )
        case .none:
            balanceColor = .Text.primary
            backupButton = nil
        }

        let amountButtonConfiguration: BalanceHeaderBalanceAmountButton.Configuration = {
            let amountButtonState: BalanceHeaderBalanceAmountButton.State
            if state.isSecure {
                amountButtonState = .secure(color: balanceColor)
            } else {
                amountButtonState = .amount(
                    BalanceHeaderBalanceAmountButton.State.Amount(
                        balance: totalBalanceMapped,
                        color: balanceColor
                    )
                )
            }

            return BalanceHeaderBalanceAmountButton.Configuration(
                state: amountButtonState,
                action: { [weak self] in
                    self?.appSettingsStore.toggleIsSecureMode()
                }
            )
        }()

        let batteryButtonConfiguration = createBatteryButtonConfiguration(
            wallet: state.wallet,
            batteryBalance: state.totalBalanceState?.totalBalance?.batteryBalance
        )

        return BalanceHeaderBalanceAmountView.Configuration(
            amountButtonConfiguration: amountButtonConfiguration,
            batteryButtonConfiguration: batteryButtonConfiguration,
            backupButton: backupButton
        )
    }

    func createBatteryButtonConfiguration(
        wallet: Wallet,
        batteryBalance: BatteryBalance?
    ) -> BalanceHeaderBalanceBatteryButton.Configuration? {
        guard wallet.kind == .regular else { return nil }
        let batteryDisabled = configuration.flag(\.batteryDisabled, network: wallet.network)

        let state: BatteryView.State
        switch (batteryBalance?.batteryState, batteryDisabled) {
        case let (.fill(percents), _):
            state = .fill(percents)
        case let (.empty, disabled):
            if disabled { return nil }
            state = .emptyTinted
        case let (.none, disabled):
            if disabled { return nil }
            state = .emptyTinted
        }
        return BalanceHeaderBalanceBatteryButton.Configuration(
            batteryConfiguration: state,
            action: { [weak self] in
                self?.didTapBattery?(wallet)
            }
        )
    }

    func didUpdateTotalBalanceState(_ state: WalletTotalBalanceModel.State) {
        syncQueue.async {
            if state.isLoadingBalance {
                if self.loadBalanceTrace == nil {
                    self.loadBalanceTrace = Trace(name: "load_balance")
                }
            } else {
                self.loadBalanceTrace?.stop()
                self.loadBalanceTrace = nil
            }

            let model = self.createHeaderModel(totalBalanceModelState: state)
            DispatchQueue.main.async {
                self.didUpdateHeader?(model)
            }
        }
    }

    func createConnectionStatusModel(backgroundUpdateState: BackgroundUpdateConnectionState, isLoading: Bool) -> BalanceHeaderBalanceConnectionStatusView.Model? {
        switch (backgroundUpdateState, isLoading) {
        case (.connecting, _):
            return BalanceHeaderBalanceConnectionStatusView.Model(
                title: TKLocales.ConnectionStatus.updating,
                titleColor: .Text.secondary,
                isLoading: true
            )
        case (.connected, false):
            return nil
        case (.connected, true):
            return BalanceHeaderBalanceConnectionStatusView.Model(
                title: TKLocales.ConnectionStatus.updating,
                titleColor: .Text.secondary,
                isLoading: true
            )
        case (.disconnected, _):
            return BalanceHeaderBalanceConnectionStatusView.Model(
                title: TKLocales.ConnectionStatus.updating,
                titleColor: .Text.secondary,
                isLoading: true
            )
        case (.noConnection, _):
            return BalanceHeaderBalanceConnectionStatusView.Model(
                title: TKLocales.ConnectionStatus.noInternet,
                titleColor: .Accent.orange,
                isLoading: false
            )
        }
    }

    func createHeaderButtonsRedesignModel(wallet: Wallet) -> WalletBalanceHeaderButtonsRedesignView.Model {
        let withdrawButton = WalletBalanceHeaderButtonsRedesignView.Model.Button(
            title: TKLocales.WalletButtons.send,
            icon: .TKUIKit.Icons.Size28.arrowUpOutline,
            isEnabled: wallet.isSendEnable, // TODO: - enabled flag
            action: { [weak self] in
                guard let self else { return }
                tooltipsService.didPerformTooltipTargetAction(id: .walletBalanceWithdraw)
                didTapWithdraw?(wallet)
            }
        )
        let depositButton = WalletBalanceHeaderButtonsRedesignView.Model.Button(
            title: TKLocales.WalletButtons.deposit,
            icon: .TKUIKit.Icons.Size28.arrowDownOutline,
            isEnabled: wallet.isReceiveEnable, // TODO: - enabled flag
            action: { [weak self] in self?.didTapDeposit?(wallet) }
        )

        let swapButton: WalletBalanceHeaderButtonsRedesignView.Model.Button? = {
            guard !configuration.flag(\.isSwapDisable, network: wallet.network) else { return nil }
            return WalletBalanceHeaderButtonsRedesignView.Model.Button(
                title: TKLocales.WalletButtons.swap,
                icon: .TKUIKit.Icons.Size28.swapHorizontalOutline,
                isEnabled: wallet.isSwapEnable,
                action: { [weak self] in self?.didTapSwap?(wallet) }
            )
        }()
        let stakeButton: WalletBalanceHeaderButtonsRedesignView.Model.Button? = {
            guard !configuration.flag(\.stakingDisabled, network: wallet.network) else { return nil }
            return WalletBalanceHeaderButtonsRedesignView.Model.Button(
                title: TKLocales.WalletButtons.stake,
                icon: .TKUIKit.Icons.Size28.stakingOutline,
                isEnabled: wallet.isStakeEnable,
                action: { [weak self] in self?.didTapStake?(wallet) }
            )
        }()

        return WalletBalanceHeaderButtonsRedesignView.Model(
            withdrawButton: withdrawButton,
            depositButton: depositButton,
            swapButton: swapButton,
            stakeButton: stakeButton,
            withdrawTooltipEnabled: wallet.isSendEnable
        )
    }

    func didTapCopy(address: String, toastConfiguration: ToastPresenter.Configuration) {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        UIPasteboard.general.string = address

        didCopy?(toastConfiguration)
    }
}

private extension String {
    static let setupSectionHeaderIdentifier = "SetupSectionHeaderIdentifier"
}

private extension Array where Element == WalletBalanceBalanceModel.Item {
    func getStakingItems() -> [WalletBalanceBalanceModel.Item] {
        self.compactMap {
            guard case .staking = $0.balanceItem else {
                return nil
            }
            return $0
        }
    }
}
