import Foundation
import KeeperCore

struct PasscodeConfirmationValidator: PasscodeInputValidator {
    private let mnemonicAccess: MnemonicAccess

    init(mnemonicAccess: MnemonicAccess) {
        self.mnemonicAccess = mnemonicAccess
    }

    func validate(passcode: String) async -> PasscodeInputValidationResult {
        await mnemonicAccess.validatePasscode(passcode) ? .success : .failed
    }

    func getPasscode() throws -> String {
        try mnemonicAccess.getPasscode()
    }

    func resetPasscodeStorage() throws {
        try mnemonicAccess.deletePasscode()
    }
}
