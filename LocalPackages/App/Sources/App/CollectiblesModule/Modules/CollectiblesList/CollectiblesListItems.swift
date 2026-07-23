import UIKit

enum CollectiblesList {
    enum SnapshotSection: Hashable {
        case all
        case empty
    }

    enum SnapshotItem: Hashable {
        case nft(identifier: String)
        case customChannel(identifier: String)
        case empty
    }
    
    // Alias for Item
    typealias Item = SnapshotItem

    typealias DataSource = UICollectionViewDiffableDataSource<SnapshotSection, SnapshotItem>
    typealias Snapshot = NSDiffableDataSourceSnapshot<SnapshotSection, SnapshotItem>
}
