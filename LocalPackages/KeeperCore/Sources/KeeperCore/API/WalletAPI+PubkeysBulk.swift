import Foundation
import TonAPI

struct PubkeysWalletsBulkRequest: Encodable {
    let publicKeys: [String]

    enum CodingKeys: String, CodingKey {
        case publicKeys = "public_keys"
    }
}

struct PubkeysWalletsBulkResponse: Decodable {
    let items: [PubkeyWalletsBulkItem]
}

struct PubkeyWalletsBulkItem: Decodable {
    let publicKey: String
    let wallets: [TonAPI.Wallet]

    enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
        case wallets
    }
}

extension WalletAPI {
    static func getWalletsByPublicKeysBulkWithRequestBuilder(
        request: PubkeysWalletsBulkRequest,
        firebaseUserId: String?
    ) -> RequestBuilder<PubkeysWalletsBulkResponse> {
        let localVariablePath = "/v2/pubkeys/wallets/_bulk"
        let localVariableURLString = TonAPIAPI.basePath + localVariablePath
        let localVariableParameters = JSONEncodingHelper.encodingParameters(forEncodableObject: request)
        let localVariableUrlComponents = URLComponents(string: localVariableURLString)
        let localVariableNillableHeaders: [String: Any?] = [
            "Content-Type": "application/json",
            "F": firebaseUserId,
        ]
        let localVariableHeaderParameters = APIHelper.rejectNilHeaders(localVariableNillableHeaders)
        let localVariableRequestBuilder: RequestBuilder<PubkeysWalletsBulkResponse>.Type = TonAPIAPI.requestBuilderFactory.getBuilder()
        return localVariableRequestBuilder.init(
            method: "POST",
            URLString: (localVariableUrlComponents?.string ?? localVariableURLString),
            parameters: localVariableParameters,
            headers: localVariableHeaderParameters,
            requiresAuthentication: false
        )
    }
}
