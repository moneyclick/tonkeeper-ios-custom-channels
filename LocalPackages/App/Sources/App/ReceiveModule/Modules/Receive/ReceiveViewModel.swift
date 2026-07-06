import Combine
import KeeperCore
import TKCore
import TKLocalize
import TKUIKit
import UIKit

public protocol ReceiveModuleOutput: AnyObject {
    var didRequestClose: (() -> Void)? { get set }
}

public protocol ReceiveModuleInput: AnyObject {}

struct ReceiveNetworkViewData: Identifiable {
    let chain: MultichainChain
    let addressTitle: String
    let title: String
    let address: String
    let shortAddress: String
    let disclaimer: String
    let icon: UIImage
    let primaryColor: UIColor
    let secondaryColor: UIColor

    var id: MultichainChain {
        chain
    }
}

final class ReceiveViewModelImplementation: ObservableObject, ReceiveModuleOutput, ReceiveModuleInput {
    @Published private(set) var qrCodeImage: UIImage?
    let selectedNetwork: ReceiveNetworkViewData

    var didRequestClose: (() -> Void)?
    var didRequestShare: ((MultichainWalletAddress) -> Void)?
    var didRequestCopy: ((MultichainWalletAddress) -> Void)?

    private let address: MultichainWalletAddress
    private let qrCodeGenerator: QRCodeGenerator
    private var qrCodeTask: Task<Void, Never>?

    init(
        address: MultichainWalletAddress,
        qrCodeGenerator: QRCodeGenerator
    ) {
        self.address = address
        self.qrCodeGenerator = qrCodeGenerator
        let network = address.receiveNetworkViewData
        selectedNetwork = network
    }

    deinit {
        qrCodeTask?.cancel()
    }

    func viewDidLoad() {
        regenerateQRCode()
    }

    func close() {
        didRequestClose?()
    }

    func copyAddress() {
        didRequestCopy?(address)
    }

    func shareSelectedAddress() {
        didRequestShare?(address)
    }
}

private extension ReceiveViewModelImplementation {
    func regenerateQRCode() {
        qrCodeTask?.cancel()
        qrCodeImage = nil

        qrCodeTask = Task { [weak self] in
            guard let self else { return }
            let image = await qrCodeGenerator.generate(
                string: address.address,
                size: Constants.qrCodeSize,
                cgImageBacked: true
            )
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.qrCodeImage = image
            }
        }
    }
}

private extension ReceiveViewModelImplementation {
    enum Constants {
        static let qrCodeSize = CGSize(width: 240, height: 240)
    }
}

private struct ReceiveMultichainConfiguration {
    let title: String
    let disclaimerTitle: String
    let icon: UIImage
    let primaryColor: UIColor
    let secondaryColor: UIColor
}

private extension MultichainWalletAddress {
    var receiveNetworkViewData: ReceiveNetworkViewData {
        let configuration = chain.receiveMultichainConfiguration
        return ReceiveNetworkViewData(
            chain: chain,
            addressTitle: TKLocales.Receive.Multichain.addressTitle(configuration.disclaimerTitle),
            title: configuration.title,
            address: address,
            shortAddress: address.shortReceiveAddress,
            disclaimer: TKLocales.Receive.Multichain.disclaimer(configuration.disclaimerTitle),
            icon: configuration.icon,
            primaryColor: configuration.primaryColor,
            secondaryColor: configuration.secondaryColor
        )
    }
}

private extension MultichainChain {
    var receiveMultichainConfiguration: ReceiveMultichainConfiguration {
        switch self {
        case .ton:
            ReceiveMultichainConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Ton.title,
                disclaimerTitle: TKLocales.Receive.Multichain.Networks.Ton.title,
                icon: .TKUIKit.Icons.Size44.tonChain,
                primaryColor: .Accent.blue,
                secondaryColor: .Accent.blue.withAlphaComponent(0.16)
            )
        case .eth:
            ReceiveMultichainConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Ethereum.title,
                disclaimerTitle: TKLocales.Receive.Multichain.Networks.Ethereum.title,
                icon: .TKUIKit.Icons.Size44.ethChain,
                primaryColor: .Accent.blue,
                secondaryColor: .Accent.blue.withAlphaComponent(0.16)
            )
        case .btc:
            ReceiveMultichainConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Bitcoin.title,
                disclaimerTitle: TKLocales.Receive.Multichain.Networks.Bitcoin.title,
                icon: .TKUIKit.Icons.Size44.btcChain,
                primaryColor: .Accent.orange,
                secondaryColor: .Accent.orange.withAlphaComponent(0.16)
            )
        case .base:
            ReceiveMultichainConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Base.title,
                disclaimerTitle: TKLocales.Receive.Multichain.Networks.Base.title,
                icon: .TKUIKit.Icons.Size44.baseChain,
                primaryColor: .Accent.blue,
                secondaryColor: .Accent.blue.withAlphaComponent(0.16)
            )
        case .bsc:
            ReceiveMultichainConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Smartchain.title,
                disclaimerTitle: TKLocales.Receive.Multichain.Networks.Smartchain.disclaimerTitle,
                icon: .TKUIKit.Icons.Size44.bscChain,
                primaryColor: .Accent.orange,
                secondaryColor: .Accent.orange.withAlphaComponent(0.16)
            )
        case .arb:
            ReceiveMultichainConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Arbitrum.title,
                disclaimerTitle: TKLocales.Receive.Multichain.Networks.Arbitrum.title,
                icon: .TKUIKit.Icons.Size44.arbitrumChain,
                primaryColor: .Accent.blue,
                secondaryColor: .Accent.blue.withAlphaComponent(0.16)
            )
        case .tron:
            ReceiveMultichainConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Tron.title,
                disclaimerTitle: TKLocales.Receive.Multichain.Networks.Tron.title,
                icon: .TKUIKit.Icons.Size44.trxChain,
                primaryColor: .Accent.red,
                secondaryColor: .Accent.red.withAlphaComponent(0.16)
            )
        case .sol:
            ReceiveMultichainConfiguration(
                title: TKLocales.Receive.Multichain.Networks.Solana.title,
                disclaimerTitle: TKLocales.Receive.Multichain.Networks.Solana.title,
                icon: .TKUIKit.Icons.Size44.solChain,
                primaryColor: .Accent.red,
                secondaryColor: .Accent.red.withAlphaComponent(0.16)
            )
        }
    }
}

extension String {
    var shortReceiveAddress: String {
        guard count > 14 else { return self }
        return "\(prefix(4))...\(suffix(4))"
    }
}
