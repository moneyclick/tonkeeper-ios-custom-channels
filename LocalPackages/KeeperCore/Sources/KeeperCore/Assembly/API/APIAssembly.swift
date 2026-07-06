import EventSource
import Foundation
import HTTPTypes
import MultichainAPI
import OpenAPIRuntime
import StreamURLSessionTransport
import SwapAPI
import TonAPI
import TonConnectAPI
import TonStreamingAPI
import TonStreamingAPIV2

public final class APIAssembly {
    let configurationAssembly: ConfigurationAssembly

    init(configurationAssembly: ConfigurationAssembly) {
        self.configurationAssembly = configurationAssembly
    }

    // MARK: - Internal

    var apiProvider: APIProvider {
        APIProvider { [api, testnetAPI, tetraAPI] network in
            switch network {
            case .mainnet: return api
            case .testnet: return testnetAPI
            case .tetra: return tetraAPI
            }
        }
    }

    lazy var api: API = API(
        hostProvider: tonApiHostProvider,
        urlSession: URLSession(
            configuration: urlSessionConfiguration
        ),
        configuration: configurationAssembly.configuration,
        requestCreationQueue: apiRequestCreationQueue
    )

    lazy var testnetAPI: API = API(
        hostProvider: testnetTonApiHostProvider,
        urlSession: URLSession(
            configuration: urlSessionConfiguration
        ),
        configuration: configurationAssembly.configuration,
        requestCreationQueue: apiRequestCreationQueue
    )

    lazy var tetraAPI: API = API(
        hostProvider: tetraTonApiHostProvider,
        urlSession: URLSession(
            configuration: urlSessionConfiguration
        ),
        configuration: configurationAssembly.configuration,
        requestCreationQueue: apiRequestCreationQueue
    )

    public lazy var pushNotificationsAPI: PushNotificationsAPI = PushNotificationsAPI(urlSession: .shared)

    private lazy var apiRequestCreationQueue = DispatchQueue(label: "APIRequestCreationQueue")

    private var tonApiHostProvider: APIHostProvider {
        MainnetAPIHostProvider(configuration: configurationAssembly.configuration)
    }

    private var testnetTonApiHostProvider: APIHostProvider {
        TestnetAPIHostProvider(configuration: configurationAssembly.configuration)
    }

    private var tetraTonApiHostProvider: APIHostProvider {
        TetraAPIHostProvider(configuration: configurationAssembly.configuration)
    }

    var streamingAPIProvider: StreamingAPIProvider {
        StreamingAPIProvider { [streamingAPI, testnetStreamingAPI] network in
            switch network {
            case .mainnet: return streamingAPI
            case .testnet: return testnetStreamingAPI
            case .tetra: return nil
            }
        }
    }

    var streamingAPIV2Provider: StreamingAPIV2Provider {
        StreamingAPIV2Provider { [streamingAPIV2Task, testnetStreamingAPIV2Task] network in
            switch network {
            case .mainnet: return await streamingAPIV2Task.value
            case .testnet: return await testnetStreamingAPIV2Task.value
            case .tetra: return nil
            }
        }
    }

    private func makeStreamingAPI(for network: Network) -> TonStreamingAPI.StreamingAPI {
        let configuration = configurationAssembly.configuration
        return TonStreamingAPI.StreamingAPI(
            configuration: streamingUrlSessionConfiguration,
            hostProvider: { [streamingAPIURL] in
                guard let url = await URL(string: configuration.tonAPISSEEndpoint(network: network)) else {
                    return streamingAPIURL
                }
                return url
            },
            tokenProvider: {
                await configuration.tonApiV2Key
            }
        )
    }

    private func makeStreamingAPIV2(for network: Network) async -> TonStreamingAPIV2.StreamingAPI? {
        let configuration = configurationAssembly.configuration
        guard configuration.featureEnabled(.streamingApiV2Enabled) else {
            return nil
        }

        guard let endpoint = await configuration.tonAPISSEEndpointV2(network: network),
              !endpoint.isEmpty,
              let host = URL(string: endpoint)
        else {
            return nil
        }

        return TonStreamingAPIV2.StreamingAPI(
            configuration: streamingUrlSessionConfiguration,
            hostProvider: {
                host
            },
            tokenProvider: {
                await configuration.tonApiV2Key
            }
        )
    }

    private lazy var streamingAPI: TonStreamingAPI.StreamingAPI = makeStreamingAPI(for: .mainnet)

    private lazy var testnetStreamingAPI: TonStreamingAPI.StreamingAPI = makeStreamingAPI(for: .testnet)

    private lazy var streamingAPIV2Task: Task<TonStreamingAPIV2.StreamingAPI?, Never> = Task {
        await makeStreamingAPIV2(for: .mainnet)
    }

    private lazy var testnetStreamingAPIV2Task: Task<TonStreamingAPIV2.StreamingAPI?, Never> = Task {
        await makeStreamingAPIV2(for: .testnet)
    }

    var tonConnectBridgeAPIClientProvider: TonConnectBridgeAPIClientProvider {
        TonConnectBridgeAPIClientProvider(
            tonConnectBridgerAPIClient: { await self.tonConnectAPIClient }
        )
    }

    func swapAPIClient(userAgent: String? = nil) -> SwapAPI.Client {
        let url = configurationAssembly.configuration.value(\.webSwapsUrl, network: .mainnet)
            ?? swapAPIURL
        return SwapAPI.Client(
            serverURL: url,
            transport: swapAPITransport,
            middlewares: [
                UserAgentHeaderMiddleware(userAgent: userAgent),
            ]
        )
    }

    func multichainAPIClient(userAgent: String? = nil) -> MultichainAPI.Client {
        MultichainAPI.Client(
            serverURL: multichainAPIURL,
            transport: multichainAPITransport,
            middlewares: [
                UserAgentHeaderMiddleware(userAgent: userAgent),
            ]
        )
    }

    private actor TonConnectAPIClientWrapper {
        var _tonConnectAPIClient: TonConnectAPI.Client?
        func setApiClient(tonConnectAPIClient: TonConnectAPI.Client) {
            self._tonConnectAPIClient = tonConnectAPIClient
        }
    }

    private let tonConnectAPIClientWrapper = TonConnectAPIClientWrapper()
    var tonConnectAPIClient: TonConnectAPI.Client {
        get async {
            if let tonConnectAPIClient = await tonConnectAPIClientWrapper._tonConnectAPIClient {
                return tonConnectAPIClient
            }
            let tonConnectBridge = await configurationAssembly.configuration.tonConnectBridge
            let tonConnectAPIClient = TonConnectAPI.Client(
                serverURL: (URL(string: tonConnectBridge) ?? tonConnectURL).appendingPathComponent("bridge"),
                transport: streamingTransport,
                middlewares: []
            )
            await tonConnectAPIClientWrapper.setApiClient(tonConnectAPIClient: tonConnectAPIClient)
            return tonConnectAPIClient
        }
    }

    // MARK: - Private

    private lazy var streamingTransport: StreamURLSessionTransport = StreamURLSessionTransport(urlSessionConfiguration: streamingUrlSessionConfiguration)

    private lazy var swapAPITransport: StreamURLSessionTransport = StreamURLSessionTransport(urlSessionConfiguration: urlSessionConfiguration)

    private lazy var multichainAPITransport: StreamURLSessionTransport = StreamURLSessionTransport(urlSessionConfiguration: urlSessionConfiguration)

    private var urlSessionConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 60
        return configuration
    }

    private var streamingUrlSessionConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = TimeInterval(Int.max)
        configuration.timeoutIntervalForResource = TimeInterval(Int.max)
        return configuration
    }

    var tonAPIURL: URL {
        URL(string: "https://keeper.tonapi.io")!
    }

    var streamingAPIURL: URL {
        URL(string: "https://rt.tonapi.io")!
    }

    var testnetTonAPIURL: URL {
        URL(string: "https://testnet.tonapi.io")!
    }

    var tonConnectURL: URL {
        URL(string: "https://bridge.tonapi.io")!
    }

    private var swapAPIURL: URL {
        URL(string: "https://swap.tonkeeper.com")!
    }

    var tonConnectBridgeURL: URL {
        URL(string: "https://bridge.tonapi.io/bridge")!
    }

    private var multichainAPIURL: URL {
        // TODO: - [Multichain] change to prod url
        URL(string: "https://multi-dev.tonkeeper.com")!
    }
}

private struct UserAgentHeaderMiddleware: ClientMiddleware {
    let userAgent: String?

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID _: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        guard let userAgent else {
            return try await next(request, body, baseURL)
        }

        var request = request
        request.headerFields[.userAgent] = userAgent
        return try await next(request, body, baseURL)
    }
}
