//
//  TONWalletKitSignRawResultHandler.swift
//  WalletCore
//
//  Created by Nikita Rodionov on 16.02.2026.
//

import Foundation
import TKLogging
import TONWalletKit

public struct TONWalletKitSignRawResultHandler: SignRawControllerResultHandler {
    public var didCancelHandler: (() -> Void)?

    private let transactionRequest: TONWalletSendTransactionRequest
    private let app: TonConnectApp

    public init(
        transactionRequest: TONWalletSendTransactionRequest,
        app: TonConnectApp
    ) {
        self.transactionRequest = transactionRequest
        self.app = app
    }

    public func didConfirm(boc: String) {
        Task {
            do {
                let response = try TONSendTransactionApprovalResponse(
                    signedBoc: TONBase64(base64Encoded: boc)
                )
                try await transactionRequest.approve(response: response)
            } catch {
                Log.e(
                    "\(String(reflecting: Self.self)): failed to approve send-transaction request",
                    extraInfo: [
                        "error": error.localizedDescription,
                        "dappHost": app.manifest.host,
                    ]
                )
            }
        }
    }

    public func didFail(error: SomeOf<TransferError, TransactionConfirmationError>) {
        Task {
            do {
                try await transactionRequest.reject(reason: error.localizedDescription)
            } catch {
                Log.e(
                    "\(String(reflecting: Self.self)): failed to reject send-transaction request after didFail",
                    extraInfo: [
                        "error": error.localizedDescription,
                        "dappHost": app.manifest.host,
                    ]
                )
            }
        }
    }

    public func didCancel() {
        didCancelHandler?()
        Task {
            do {
                try await transactionRequest.reject()
            } catch {
                Log.e(
                    "\(String(reflecting: Self.self)): failed to reject send-transaction request after user cancel",
                    extraInfo: [
                        "error": error.localizedDescription,
                        "dappHost": app.manifest.host,
                    ]
                )
            }
        }
    }
}
