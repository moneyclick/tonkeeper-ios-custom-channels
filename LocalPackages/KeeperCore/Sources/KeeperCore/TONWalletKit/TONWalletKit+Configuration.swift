import Foundation
import TONWalletKit

extension TONWalletKit {
    convenience init(
        tonConnectService: TonConnectService,
        walletsStore: WalletsStore,
        appsStore: TonConnectAppsStore,
        bridgeURL: URL
    ) {
        let bridgeURL = bridgeURL.absoluteString
        let apiClientConfig = TONWalletKitConfiguration.APIClientConfiguration(key: "")
        let mainNetworkConfiguration = TONWalletKitConfiguration.NetworkConfiguration(
            network: .mainnet,
            apiClientConfiguration: apiClientConfig
        )
        let testNetworkConfiguration = TONWalletKitConfiguration.NetworkConfiguration(
            network: .testnet,
            apiClientConfiguration: apiClientConfig
        )

        let tetraNetworkConfiguration = TONWalletKitConfiguration.NetworkConfiguration(
            network: .init(chainId: String(Network.tetra.rawValue)),
            apiClientConfiguration: apiClientConfig
        )

        let sessionManager = TONConnectSessionsManagerAdapter(
            tonConnectService: tonConnectService,
            walletsStore: walletsStore,
            appsStore: appsStore
        )

        var configuration = TONWalletKitConfiguration(
            networkConfigurations: [mainNetworkConfiguration, testNetworkConfiguration, tetraNetworkConfiguration],
            walletManifest: TONWalletKitConfiguration.Manifest(
                // TODO: Move constant for name and appName into some other place
                // Currently there is already a constant for appName in InforProvider but it's in TKCore,
                // and it's not possible to connect TKCore to KeeperCore due recursive dependency issue
                name: "tonkeeper",
                appName: "Tonkeeper",
                imageUrl: "https://tonkeeper.com/assets/tonkeeper-logo.png",
                aboutUrl: "https://tonkeeper.com",
                universalLink: "https://app.tonkeeper.com/ton-connect",
                bridgeUrl: bridgeURL
            ),
            storage: .keychain,
            sessionManager: sessionManager,
            bridge: TONWalletKitConfiguration.Bridge(bridgeUrl: bridgeURL, webViewInjectionKey: "tonkeeper"),
            eventsConfiguration: TONWalletKitConfiguration.EventsConfiguration(disableTransactionEmulation: true),
            features: [
                TONSendTransactionFeature(maxMessages: 255),
                TONSignDataFeature(types: [.text, .binary, .cell]),
            ],
            devConfiguration: TONWalletKitConfiguration.DevConfiguration(disableNetworkSend: true),
            analyticsConfiguration: TONWalletKitConfiguration.AnalyticsConfiguration(analyticsEnabled: false)
        )

        configuration.fetchManifest = { url in
            guard let url = URL(string: url) else {
                return TONManifestFetchResult(manifest: nil, manifestFetchErrorCode: .badRequestError)
            }

            do {
                let manifest = try await tonConnectService.loadManifest(url: url)
                return TONManifestFetchResult(manifest: AnyCodable(manifest), manifestFetchErrorCode: nil)
            } catch let error as TonConnectManifestError {
                switch error {
                case .incorrectURL:
                    return TONManifestFetchResult(manifest: nil, manifestFetchErrorCode: .badRequestError)
                case .invalidManifest:
                    return TONManifestFetchResult(manifest: nil, manifestFetchErrorCode: .manifestContentError)
                case .loadFailed:
                    return TONManifestFetchResult(manifest: nil, manifestFetchErrorCode: .unknownError)
                }
            } catch {
                return TONManifestFetchResult(manifest: nil, manifestFetchErrorCode: .unknownError)
            }
        }

        self.init(configuration: configuration)
    }
}
