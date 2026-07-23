import Foundation
import KeeperCore
import TKLocalize
import TKUIKit
import TonSwift

@MainActor
protocol CollectiblesListModuleOutput: AnyObject {
    var didSelectNFT: ((NFT, _ wallet: Wallet) -> Void)? { get set }
}

@MainActor
protocol CollectiblesListViewModel: AnyObject {
    var didUpdateSnapshot: ((CollectiblesList.Snapshot) -> Void)? { get set }
    var didUpdateEmptyViewModel: ((TKEmptyViewController.Model) -> Void)? { get set }
    var didStopLoading: (() -> Void)? { get set }

    func viewDidLoad()
    func getNFTCellModel(identifier: String) -> CollectibleCollectionViewCell.Model?
    func didSelectNftAt(index: Int)
    func reload()
    func addCustomChannel(username: String)
}

@MainActor
final class CollectiblesListViewModelImplementation: CollectiblesListViewModel, CollectiblesListModuleOutput {
    // MARK: - CollectiblesListModuleOutput

    var didSelectNFT: ((NFT, _ wallet: Wallet) -> Void)?

    // MARK: - CollectiblesListViewModel

    var didUpdateSnapshot: ((CollectiblesList.Snapshot) -> Void)?
    var didUpdateEmptyViewModel: ((TKEmptyViewController.Model) -> Void)?
    var didStopLoading: (() -> Void)?

    func viewDidLoad() {
        loadCustomChannels()
        Task { await walletNFTsStore.addObserver(self) }

        appSettingsStore.addObserver(self) { observer, event in
            switch event {
            case .didUpdateIsSecureMode:
                observer.update()
            default: break
            }
        }

        updateEmptyView()
        update()
    }

    func getNFTCellModel(identifier: String) -> CollectibleCollectionViewCell.Model? {
        models[identifier]
    }

    func didSelectNftAt(index: Int) {
        guard let nft = nfts[safe: index] else {
            return
        }
        didSelectNFT?(nft, wallet)
    }

    func reload() {
        Task { await walletNFTsStore.loadNFTs() }
    }
    
    func addCustomChannel(username: String) {
        let imageURL = "https://cache.tonapi.io/imgproxy/6bjc3arFMRcsqoh80US6jmQ6_OIflSLewvFd1XxcuIk/rs:fill:500:500:1/g:no/\(encodeUsername(username)).webp"
        let channel = CustomChannel(username: username, imageURL: imageURL)
        customChannels.append(channel)
        saveCustomChannels()
        update()
    }
    
    private func encodeUsername(_ username: String) -> String {
        let urlString = "https://nft.fragment.com/username/\(username).webp"
        guard let data = urlString.data(using: .utf8) else { return "" }
        return data.base64EncodedString()
    }
    
    private func saveCustomChannels() {
        if let encoded = try? JSONEncoder().encode(customChannels) {
            UserDefaults.standard.set(encoded, forKey: "customChannels")
        }
    }
    
    private func loadCustomChannels() {
        if let data = UserDefaults.standard.data(forKey: "customChannels"),
           let decoded = try? JSONDecoder().decode([CustomChannel].self, from: data) {
            customChannels = decoded
        }
    }

    // MARK: - State

    private var models = [String: CollectibleCollectionViewCell.Model]()
    private var nfts = [NFT]()
    private var customChannels: [CustomChannel] = []
    
    // Custom channel structure
    struct CustomChannel: Codable {
        let username: String
        let imageURL: String
        
        var displayName: String {
            "@\(username)"
        }
    }

    // MARK: - Mapper

    private lazy var collectiblesListMapper = CollectiblesListMapper(
        walletNftManagementStore: walletNftManagementStore
    )

    // MARK: - Dependencies

    private let wallet: Wallet
    private let walletNFTsStore: WalletNFTStore
    private let walletNftManagementStore: WalletNFTsManagementStore
    private let appSettingsStore: AppSettingsStore

    // MARK: - Init

    init(
        wallet: Wallet,
        walletNFTsStore: WalletNFTStore,
        walletNftManagementStore: WalletNFTsManagementStore,
        appSettingsStore: AppSettingsStore
    ) {
        self.wallet = wallet
        self.walletNFTsStore = walletNFTsStore
        self.walletNftManagementStore = walletNftManagementStore
        self.appSettingsStore = appSettingsStore
    }
}

private extension CollectiblesListViewModelImplementation {
    func update() {
        let nfts = walletNFTsStore.state.value.nfts.visible
        let isSecureMode = appSettingsStore.getState().isSecureMode
        update(nfts: nfts, isSecureMode: isSecureMode)
    }

    func update(nfts: [NFT], isSecureMode: Bool) {
        let snapshot = self.createSnapshot(state: nfts)
        let models = self.createModels(state: nfts, isSecureMode: isSecureMode)
        self.nfts = nfts
        self.models = models
        self.didUpdateSnapshot?(snapshot)
    }

    func updateEmptyView() {
        didUpdateEmptyViewModel?(TKEmptyViewController.Model(
            title: TKLocales.Purchases.emptyPlaceholder,
            caption: nil,
            buttons: []
        ))
    }

    func createSnapshot(state: [NFT]) -> CollectiblesList.Snapshot {
        var snapshot = CollectiblesList.Snapshot()
        
        let hasContent = !state.isEmpty || !customChannels.isEmpty
        
        if !hasContent {
            snapshot.appendSections([.empty])
            snapshot.appendItems([.empty], toSection: .empty)
        } else {
            snapshot.appendSections([.all])
            
            // Add custom channels first
            let channelItems = customChannels.map { CollectiblesList.Item.customChannel(identifier: $0.username) }
            snapshot.appendItems(channelItems, toSection: .all)
            
            // Then add NFTs
            let nftItems = state.map { CollectiblesList.Item.nft(identifier: $0.address.toString()) }
            snapshot.appendItems(nftItems, toSection: .all)
        }

        if #available(iOS 15.0, *) {
            snapshot.reconfigureItems(snapshot.itemIdentifiers)
        } else {
            snapshot.reloadItems(snapshot.itemIdentifiers)
        }

        return snapshot
    }

    func createModels(state: [NFT], isSecureMode: Bool) -> [String: CollectibleCollectionViewCell.Model] {
        var result = [String: CollectibleCollectionViewCell.Model]()
        
        // Add custom channels
        for channel in customChannels {
            let model = CollectibleCollectionViewCell.Model(
                image: .url(URL(string: channel.imageURL)),
                title: channel.displayName,
                subtitle: "Telegram User",
                verification: nil,
                isOnSale: false,
                isApprovedByOwner: false,
                action: nil
            )
            result[channel.username] = model
        }
        
        // Add NFTs
        for item in state {
            let model = collectiblesListMapper.map(nft: item, isSecureMode: isSecureMode)
            let identifier = item.address.toString()
            result[identifier] = model
        }
        
        return result
    }
}

extension CollectiblesListViewModelImplementation: WalletNFTStoreObserver {
    nonisolated func didUpdateNFTs(_ nfts: WalletNFTs) {
        Task { @MainActor in update() }
    }

    nonisolated func didUpdateLoadingState(_ loadingState: WalletNFTStore.LoadingState) {
        guard loadingState == .idle else { return }
        Task { @MainActor [weak self] in self?.didStopLoading?() }
    }
}
