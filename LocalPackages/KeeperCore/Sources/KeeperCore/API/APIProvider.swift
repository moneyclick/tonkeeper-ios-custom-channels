import Foundation
import TonStreamingAPI
import TonStreamingAPIV2

struct APIProvider {
    var api: (_ network: Network) -> API
}

struct StreamingAPIProvider {
    var api: (_ network: Network) -> TonStreamingAPI.StreamingAPI?
}

struct StreamingAPIV2Provider {
    var api: (_ network: Network) async -> TonStreamingAPIV2.StreamingAPI?
}
