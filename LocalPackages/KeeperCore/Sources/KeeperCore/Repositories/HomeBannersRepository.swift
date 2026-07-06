import Foundation
import KeeperCoreComponents

public struct HomeBannersRepository {
    let fileSystemVault: FileSystemVault<[String], String>

    public func getDismissedBannerIds() -> [String] {
        let ids = try? fileSystemVault.loadItem(key: .dismissedHomeBannerIds)
        return ids ?? []
    }

    public func appendDismissedBannerId(_ id: String) {
        var ids = getDismissedBannerIds()
        guard !ids.contains(id) else { return }
        ids.append(id)
        try? fileSystemVault.saveItem(ids, key: .dismissedHomeBannerIds)
    }

    public func resetDismissedBannerIds() {
        try? fileSystemVault.saveItem([String](), key: .dismissedHomeBannerIds)
    }
}

private extension String {
    static let dismissedHomeBannerIds = "dismissedHomeBannerIds"
}
