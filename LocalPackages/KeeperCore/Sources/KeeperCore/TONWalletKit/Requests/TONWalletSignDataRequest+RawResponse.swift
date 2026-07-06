import Foundation
import TKLogging
import TONWalletKit

public extension TONWalletSignDataRequest {
    @discardableResult
    func approve(rawResponse: Data) async throws -> TONSignDataApprovalResponse {
        guard let json = try JSONSerialization.jsonObject(with: rawResponse) as? [String: Any],
              let result = json["result"] as? [String: Any]
        else {
            throw "Invalid sign data response structure"
        }

        let responseData: Data
        do {
            responseData = try JSONSerialization.data(withJSONObject: result)
        } catch {
            Log.e(
                "\(String(reflecting: Self.self)): failed to re-serialize result payload in approve(rawResponse:)",
                extraInfo: [
                    "error": error.localizedDescription,
                ]
            )
            throw error
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(TONSignDataApprovalResponse.self, from: responseData)
        return try await approve(response: response)
    }
}
