import Foundation

public final class HomeBannersStore: Store<HomeBannersStore.Event, HomeBannersStore.State> {
    public typealias State = [HomeBanner]

    public enum Event {
        case didUpdateBannersData(visibleBanners: [HomeBanner])
        case didUpdateVisibleBanners([HomeBanner])
    }

    private let repository: HomeBannersRepository

    init(repository: HomeBannersRepository) {
        self.repository = repository
        super.init(state: [])
    }

    override public func createInitialState() -> State {
        []
    }

    public func visibleBanners() -> [HomeBanner] {
        visibleBanners(from: state)
    }

    public func setBanners(_ banners: [HomeBanner]) async {
        await withCheckedContinuation { continuation in
            setBanners(banners) {
                continuation.resume()
            }
        }
    }

    public func dismissBanner(id: String) async {
        await withCheckedContinuation { continuation in
            dismissBanner(id: id) {
                continuation.resume()
            }
        }
    }

    public func resetDismissedBanners() {
        repository.resetDismissedBannerIds()
        sendEvent(.didUpdateBannersData(visibleBanners: visibleBanners()))
    }

    private func setBanners(_ banners: [HomeBanner], completion: (() -> Void)? = nil) {
        updateState { _ in
            StateUpdate(newState: banners)
        } completion: { [weak self] _ in
            guard let self else {
                completion?()
                return
            }
            self.sendEvent(.didUpdateBannersData(visibleBanners: self.visibleBanners()))
            completion?()
        }
    }

    private func dismissBanner(id: String, completion: (() -> Void)? = nil) {
        repository.appendDismissedBannerId(id)
        sendEvent(.didUpdateVisibleBanners(visibleBanners()))
        completion?()
    }

    private func visibleBanners(from banners: [HomeBanner]) -> [HomeBanner] {
        let dismissedIds = Set(repository.getDismissedBannerIds())
        return banners.filter { !dismissedIds.contains($0.id) }
    }
}
