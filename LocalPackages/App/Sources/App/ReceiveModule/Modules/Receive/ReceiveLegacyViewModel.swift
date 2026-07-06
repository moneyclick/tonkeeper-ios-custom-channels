import Foundation
import KeeperCore
import TKCore
import TKLocalize

protocol ReceiveLegacyViewModel: AnyObject {
    var didUpdateTokenViewController: ((ReceiveTabViewController, _ animated: Bool) -> Void)? { get set }
    var didUpdateSegmentedControl: (([String]?) -> Void)? { get set }
    var didChangeIndex: ((Int) -> Void)? { get set }
    var didRequestClose: (() -> Void)? { get set }

    func viewDidLoad()
    func setActiveIndex(_ from: Int, _ to: Int)
    func close()
}

final class ReceiveLegacyViewModelImplementation: ReceiveLegacyViewModel, ReceiveModuleOutput, ReceiveModuleInput {
    var didRequestClose: (() -> Void)?
    var didDisplayToken: ((ReceiveLegacyToken) -> Void)?

    var didUpdateTokenViewController: ((ReceiveTabViewController, _ animated: Bool) -> Void)?
    var didUpdateSegmentedControl: (([String]?) -> Void)?
    var didChangeIndex: ((Int) -> Void)?

    private var activeTokenIndex = 0

    private let didSelectInactiveTRC20: ((Wallet) -> Void)?
    private let tokens: [ReceiveLegacyToken]
    private var wallet: Wallet
    private let walletsStore: WalletsStore
    private let tokenModuleViewControllerProvider: (ReceiveLegacyToken) -> ReceiveTabViewController

    init(
        tokens: [ReceiveLegacyToken],
        wallet: Wallet,
        walletsStore: WalletsStore,
        didSelectInactiveTRC20: ((Wallet) -> Void)?,
        tokenModuleViewControllerProvider: @escaping (ReceiveLegacyToken) -> ReceiveTabViewController
    ) {
        self.tokens = tokens
        self.wallet = wallet
        self.walletsStore = walletsStore
        self.didSelectInactiveTRC20 = didSelectInactiveTRC20
        self.tokenModuleViewControllerProvider = tokenModuleViewControllerProvider
    }

    func viewDidLoad() {
        setup()
    }

    func setActiveIndex(_ from: Int, _ to: Int) {
        let index = min(tokens.count - 1, max(0, to))
        if case .tron = tokens[index], !wallet.isTronTurnOn {
            didChangeIndex?(from)
            didSelectInactiveTRC20?(wallet)
            return
        }
        activeTokenIndex = index
        setupTokenPage(animated: true)
    }

    func selectToken(token: ReceiveLegacyToken) {
        guard let index = tokens.index(of: token) else { return }
        activeTokenIndex = index
        setupTokenPage(animated: true)
        didChangeIndex?(index)
    }

    func close() {
        didRequestClose?()
    }
}

private extension ReceiveLegacyViewModelImplementation {
    func setup() {
        walletsStore.addObserver(self) { observer, event in
            switch event {
            case let .didUpdateWalletTron(wallet):
                DispatchQueue.main.async {
                    guard wallet == observer.wallet else { return }
                    observer.wallet = wallet
                }
            default:
                break
            }
        }

        guard !tokens.isEmpty else { return }
        setupSegmentedControl()
        setupTokenPage(animated: false)
    }

    func setupTokenPage(animated: Bool) {
        let token = tokens[activeTokenIndex]
        let tokenViewController = tokenModuleViewControllerProvider(token)
        didUpdateTokenViewController?(tokenViewController, animated)
        didDisplayToken?(token)
    }

    func setupSegmentedControl() {
        if tokens.count > 1 {
            let segmentedControlItems = tokens.map {
                switch $0 {
                case .ton:
                    TKLocales.Receive.Multichain.Networks.Ton.title
                case .tron:
                    TKLocales.Receive.Segments.trc20
                }
            }
            didUpdateSegmentedControl?(segmentedControlItems)
        } else {
            didUpdateSegmentedControl?(nil)
        }
    }
}
