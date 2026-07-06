import Foundation
import KeeperCore

public struct PasscodeLegacyConfirmationValidator: PasscodeInputValidator {
    private let mnemonicsRepository: MnemonicsRepository

    init(mnemonicsRepository: MnemonicsRepository) {
        self.mnemonicsRepository = mnemonicsRepository
    }

    func validate(passcode: String) async -> PasscodeInputValidationResult {
        await mnemonicsRepository.checkIfPasswordValid(passcode) ? .success : .failed
    }

    func getPasscode() throws -> String {
        try mnemonicsRepository.getPassword()
    }

    func resetPasscodeStorage() throws {
        try mnemonicsRepository.deletePassword()
    }
}
