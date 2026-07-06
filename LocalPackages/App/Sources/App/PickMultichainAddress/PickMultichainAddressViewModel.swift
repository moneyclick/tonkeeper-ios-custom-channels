import Combine
import KeeperCore
import TKLocalize
import TKUIKit
import UIKit

@MainActor
protocol PickMultichainAddressModuleOutput: AnyObject {
    var didSelectAddress: ((MultichainWalletAddress) -> Void)? { get set }
    var didCopyAddress: ((MultichainWalletAddress) -> Void)? { get set }
    var didRequestClose: (() -> Void)? { get set }
}

@MainActor
protocol PickMultichainAddressModuleInput: AnyObject {}

@MainActor
protocol PickMultichainAddressViewModel: ObservableObject {
    var items: [PickMultichainAddressItem] { get }
    var selectedAddress: MultichainWalletAddress? { get }

    func close()
    func selectAddress(_ address: MultichainWalletAddress)
    func copyAddress(_ address: MultichainWalletAddress)
}

struct PickMultichainAddressItem: Identifiable {
    let address: MultichainWalletAddress
    let title: String
    let shortAddress: String
    let icon: UIImage

    var id: MultichainWalletAddress {
        address
    }
}

enum PickMultichainAddressPresentation {
    static let rowHeight: CGFloat = 72
    static let rowHighlightHorizontalInset: CGFloat = 8
    static let rowHighlightCornerRadius: CGFloat = 18
    static let contentVerticalPadding: CGFloat = 8
}

@MainActor
final class PickMultichainAddressViewModelImplementation:
    PickMultichainAddressViewModel,
    PickMultichainAddressModuleOutput,
    PickMultichainAddressModuleInput
{
    @Published private(set) var items = [PickMultichainAddressItem]()
    private(set) var selectedAddress: MultichainWalletAddress?

    var didSelectAddress: ((MultichainWalletAddress) -> Void)?
    var didCopyAddress: ((MultichainWalletAddress) -> Void)?
    var didRequestClose: (() -> Void)?

    init(
        addresses: [MultichainWalletAddress],
        selectedAddress: MultichainWalletAddress?
    ) {
        self.selectedAddress = selectedAddress
        items = addresses.map(\.pickMultichainAddressItem)
    }

    func close() {
        didRequestClose?()
    }

    func selectAddress(_ address: MultichainWalletAddress) {
        didSelectAddress?(address)
    }

    func copyAddress(_ address: MultichainWalletAddress) {
        didCopyAddress?(address)
    }
}

private struct PickMultichainAddressConfiguration {
    let title: String
    let icon: UIImage
}

private extension MultichainWalletAddress {
    var pickMultichainAddressItem: PickMultichainAddressItem {
        PickMultichainAddressItem(
            address: self,
            title: chain.pickMultichainAddressConfiguration.title,
            shortAddress: address.shortReceiveAddress,
            icon: chain.pickMultichainAddressConfiguration.icon
        )
    }
}

private extension MultichainChain {
    var pickMultichainAddressConfiguration: PickMultichainAddressConfiguration {
        switch self {
        case .ton:
            PickMultichainAddressConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Ton.title,
                icon: .TKUIKit.Icons.Size44.tonChain
            )
        case .eth:
            PickMultichainAddressConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Ethereum.title,
                icon: .TKUIKit.Icons.Size44.ethChain
            )
        case .btc:
            PickMultichainAddressConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Bitcoin.title,
                icon: .TKUIKit.Icons.Size44.btcChain
            )
        case .base:
            PickMultichainAddressConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Base.title,
                icon: .TKUIKit.Icons.Size44.baseChain
            )
        case .bsc:
            PickMultichainAddressConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Smartchain.title,
                icon: .TKUIKit.Icons.Size44.bscChain
            )
        case .arb:
            PickMultichainAddressConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Arbitrum.title,
                icon: .TKUIKit.Icons.Size44.arbitrumChain
            )
        case .tron:
            PickMultichainAddressConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Tron.title,
                icon: .TKUIKit.Icons.Size44.trxChain
            )
        case .sol:
            PickMultichainAddressConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Solana.title,
                icon: .TKUIKit.Icons.Size44.solChain
            )
        }
    }
}
