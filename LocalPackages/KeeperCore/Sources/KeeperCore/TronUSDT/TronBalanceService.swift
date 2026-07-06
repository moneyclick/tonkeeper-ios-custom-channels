import BigInt
import Foundation
import TKLogging
import TronSwift
import TronSwiftAPI

public protocol TronBalanceService {
    func loadBalance(address: Address, includingTransferFees: Bool) async throws -> TronBalance
}

public final class TronBalanceServiceImplementation: TronBalanceService {
    private let api: TronApi

    public init(api: TronApi) {
        self.api = api
    }

    public func loadBalance(address: Address, includingTransferFees: Bool) async throws -> TronBalance {
        let usdtTask = Task {
            try await api.tronUSDTBalance(owner: address)
        }

        return try await withTaskCancellationHandler(operation: {
            if includingTransferFees {
                let trxTask = Task {
                    try await api.tronBalance(owner: address)
                }
                return try await withTaskCancellationHandler(operation: {
                    let usdtAmount = try await usdtTask.value
                    let trxAmount = try await trxTask.value
                    return TronBalance(
                        amount: usdtAmount,
                        trxAmount: trxAmount
                    )
                }, onCancel: {
                    trxTask.cancel()
                })
            } else {
                return try TronBalance(
                    amount: await usdtTask.value,
                    trxAmount: 0
                )
            }
        }, onCancel: {
            usdtTask.cancel()
        })
    }
}
