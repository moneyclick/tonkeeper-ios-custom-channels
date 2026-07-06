import Foundation

actor HomeBannersLoader {
    private var taskInProgress: Task<Void, Never>?

    private let tonkeeperAPI: TonkeeperAPI
    private let homeBannersStore: HomeBannersStore

    init(
        tonkeeperAPI: TonkeeperAPI,
        homeBannersStore: HomeBannersStore
    ) {
        self.tonkeeperAPI = tonkeeperAPI
        self.homeBannersStore = homeBannersStore
    }

    nonisolated func loadBanners() {
        Task {
            await loadBanners()
        }
    }

    private func loadBanners() async {
        if let taskInProgress {
            taskInProgress.cancel()
            self.taskInProgress = nil
        }

        let task = Task {
            guard let banners = try? await tonkeeperAPI.loadBanners() else { return }
            guard !Task.isCancelled else { return }
            await homeBannersStore.setBanners(banners)
        }
        self.taskInProgress = task
    }
}
