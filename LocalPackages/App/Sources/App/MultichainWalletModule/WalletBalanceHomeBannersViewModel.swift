import CoreGraphics
import Foundation
import KeeperCore
import TKCore
import TKUIKit

@MainActor
final class WalletBalanceHomeBannersViewModel: ObservableObject {
    @Published private(set) var bannerItems: [BannerItem] = []
    @Published private(set) var bannerItemsRevision = 0
    @Published private(set) var isSectionVisible = false
    @Published private(set) var sectionHeight = WalletBalanceHomeBannersLayout.height(remainingCount: 0)

    var onOpenDeeplink: ((Deeplink) -> Void)?
    var onOpenLink: ((URL) -> Void)?
    var onSectionVisibilityChanged: ((_ isVisible: Bool) -> Void)?
    var onSectionHeightChanged: ((_ height: CGFloat) -> Void)?

    private let homeBannersStore: HomeBannersStore
    private let deeplinkParser: DeeplinkParser
    private let analyticsProvider: AnalyticsProvider

    /// Banner ids already reported during the current on-screen appearance.
    /// Both sets are cleared in `handleBannersDisappeared`, so each appearance
    /// reports at most one view and one click per banner (keeping views and
    /// clicks symmetric for CTR).
    private var shownBannerIDs = Set<String>()
    private var clickedBannerIDs = Set<String>()

    init(
        homeBannersStore: HomeBannersStore,
        deeplinkParser: DeeplinkParser,
        analyticsProvider: AnalyticsProvider
    ) {
        self.homeBannersStore = homeBannersStore
        self.deeplinkParser = deeplinkParser
        self.analyticsProvider = analyticsProvider

        homeBannersStore.addObserver(self) { [weak self] _, event in
            guard let self else { return }
            Task { @MainActor in
                switch event {
                case let .didUpdateBannersData(banners):
                    self.reloadBannerItems(banners)
                case let .didUpdateVisibleBanners(banners):
                    self.updateSectionHeight(remainingCount: banners.count)
                    self.updateSectionVisibility(isVisible: !banners.isEmpty)
                }
            }
        } onRegistered: { [weak self] in
            guard let self else { return }
            let banners = self.homeBannersStore.visibleBanners()
            Task { @MainActor in
                self.reloadBannerItems(banners)
            }
        }
    }

    func dismissBanner(_ item: BannerItem, remainingCount: Int) {
        updateSectionHeight(remainingCount: remainingCount)

        Task {
            await homeBannersStore.dismissBanner(id: item.id)
        }
    }

    func handleBannersDisappeared() {
        shownBannerIDs.removeAll()
        clickedBannerIDs.removeAll()
    }

    func handleBannerShown(id: String) {
        guard shownBannerIDs.insert(id).inserted else { return }
        analyticsProvider.log(BannerView(bannerId: id))
    }

    private func handleBannerClick(id: String, action: BannerActionType) {
        guard clickedBannerIDs.insert(id).inserted else { return }
        analyticsProvider.log(BannerClick(bannerId: id, action: action))
    }

    private static func actionType(for deeplink: Deeplink?) -> BannerActionType {
        switch deeplink {
        case .battery: return .battery
        case .deposit, .buyTon: return .deposit
        case .withdraw: return .withdraw
        case .swap: return .swap
        case .staking, .pool: return .staking
        case .transfer: return .send
        case .trading, .tradeAsset: return .trade
        case .exchange: return .exchange
        case .dapp, .browser: return .dapp
        default: return .other
        }
    }

    private func reloadBannerItems(_ banners: [HomeBanner]) {
        let bannerItems = Array(banners.compactMap(mapBannerItem).reversed())
        self.bannerItems = bannerItems
        bannerItemsRevision += 1
        updateSectionHeight(remainingCount: bannerItems.count)
        updateSectionVisibility(isVisible: !bannerItems.isEmpty)
    }

    private func updateSectionHeight(remainingCount: Int) {
        let sectionHeight = WalletBalanceHomeBannersLayout.height(remainingCount: remainingCount)
        guard self.sectionHeight != sectionHeight else { return }
        self.sectionHeight = sectionHeight
        onSectionHeightChanged?(sectionHeight)
    }

    private func updateSectionVisibility(isVisible: Bool) {
        guard isSectionVisible != isVisible else { return }
        isSectionVisible = isVisible
        onSectionVisibilityChanged?(isVisible)
    }

    private func mapBannerItem(_ banner: HomeBanner) -> BannerItem? {
        let action: (() -> Void)? = {
            guard let button = banner.button else { return nil }
            switch button.type {
            case let .deeplink(url):
                return { [weak self] in
                    guard let self else { return }
                    let deeplink = try? self.deeplinkParser.parse(string: url.absoluteString)
                    self.handleBannerClick(id: banner.id, action: Self.actionType(for: deeplink))
                    guard let deeplink else { return }
                    self.onOpenDeeplink?(deeplink)
                }
            case let .link(url):
                return { [weak self] in
                    guard let self else { return }
                    self.handleBannerClick(id: banner.id, action: .other)
                    self.onOpenLink?(url)
                }
            case .unknown:
                return nil
            }
        }()

        return BannerItem(
            id: banner.id,
            title: banner.title,
            description: banner.description,
            actionTitle: banner.button?.title ?? "",
            imageURL: banner.image,
            action: action
        )
    }
}
