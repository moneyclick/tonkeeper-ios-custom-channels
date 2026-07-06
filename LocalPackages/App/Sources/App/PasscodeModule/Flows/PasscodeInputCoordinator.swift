import KeeperCore
import KeeperCoreSensitive
import Security
import TKCoordinator
import TKLocalize
import TKLogging
import TKUIKit
import UIKit

protocol PasscodeInputValidator {
    func validate(passcode: String) async -> PasscodeInputValidationResult
    func getPasscode() throws -> String
    func resetPasscodeStorage() throws
}

protocol PasscodeInputBiometryProvider {
    func getBiometryState() async -> TKKeyboardView.Biometry
}

final class PasscodeInputCoordinator: RouterCoordinator<NavigationControllerRouter> {
    enum Context {
        case entry
        case confirmation
    }

    var didInputPasscode: ((String) -> Void)?
    var didCancel: (() -> Void)?
    var didLogout: (() -> Void)?

    private let validator: PasscodeInputValidator
    private let biometryProvider: PasscodeInputBiometryProvider
    private let securityStore: SecurityStore
    private let context: Context

    init(
        router: NavigationControllerRouter,
        context: Context,
        validator: PasscodeInputValidator,
        biometryProvider: PasscodeInputBiometryProvider,
        securityStore: SecurityStore
    ) {
        self.context = context
        self.validator = validator
        self.biometryProvider = biometryProvider
        self.securityStore = securityStore
        super.init(router: router)
        router.rootViewController.modalPresentationStyle = .fullScreen
        router.rootViewController.modalTransitionStyle = .crossDissolve
    }

    override func start() {
        openPasscode()
    }
}

private extension PasscodeInputCoordinator {
    func openPasscode() {
        let navigationController = TKNavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)

        let passcodeInputModule = PasscodeInputAssembly.module(
            title: TKLocales.Passcode.enter
        )

        let passcodeModule = PasscodeAssembly.module(
            navigationController: navigationController
        )

        passcodeInputModule.output.validateInput = { [weak self] input in
            guard let self else { return .failed }
            return await Task {
                await self.validator.validate(passcode: input)
            }.value
        }

        passcodeInputModule.output.didFinish = { [weak self] passcode in
            self?.didInputPasscode?(passcode)
        }
        passcodeModule.output.didTapBackspace = {
            passcodeInputModule.input.didTapBackspace()
        }

        passcodeModule.output.didTapDigit = { digit in
            passcodeInputModule.input.didTapDigit(digit)
        }

        passcodeModule.output.didTapBiometry = { [weak self] in
            Task {
                guard let self else { return }
                do {
                    let passcode = try self.validator.getPasscode()
                    await MainActor.run {
                        passcodeInputModule.input.didSetInput(passcode)
                    }
                } catch {
                    Log.w("Failed to fetch passcode from repository", extraInfo: [
                        "error": error.localizedDescription,
                    ])
                }
            }
        }

        passcodeModule.output.biometryProvider = { [weak self] in
            await self?.biometryProvider.getBiometryState() ?? .none
        }

        switch context {
        case .entry:
            passcodeModule.view.setupLogoutButton(title: TKLocales.Passcode.logout) { [weak self] in
                self?.showLogoutConfirmationAlert { self?.didLogout?() }
            }
        case .confirmation:
            passcodeModule.view.setupLeftCloseButton { [weak self] in
                self?.didCancel?()
            }
        }

        navigationController.pushViewController(passcodeInputModule.viewController, animated: false)

        router.push(viewController: passcodeModule.view)
    }

    func showLogoutConfirmationAlert(completion: @escaping (() -> Void)) {
        let alertController = UIAlertController(
            title: TKLocales.Passcode.logoutConfirmationTitle,
            message: TKLocales.Passcode.logoutConfirmationDescription,
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(title: TKLocales.Actions.cancel, style: .cancel)
        let logoutAction = UIAlertAction(title: TKLocales.SignOutWarning.title, style: .destructive) { _ in
            completion()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(logoutAction)
        router.rootViewController.present(alertController, animated: true)
    }
}

extension PasscodeInputCoordinator {
    static func present<ParentRouterViewController: UIViewController>(
        parentCoordinator: Coordinator,
        parentRouter: ContainerViewControllerRouter<ParentRouterViewController>,
        mnemonicAccess: MnemonicAccess,
        securityStore: SecurityStore,
        onCancel: @escaping () -> Void,
        onInput: @escaping (String) -> Void
    ) {
        present(
            parentCoordinator: parentCoordinator,
            parentRouter: parentRouter,
            validator: PasscodeConfirmationValidator(
                mnemonicAccess: mnemonicAccess
            ),
            securityStore: securityStore,
            onCancel: onCancel,
            onInput: onInput
        )
    }

    static func present<ParentRouterViewController: UIViewController>(
        parentCoordinator: Coordinator,
        parentRouter: ContainerViewControllerRouter<ParentRouterViewController>,
        validator: PasscodeInputValidator,
        securityStore: SecurityStore,
        onCancel: @escaping () -> Void,
        onInput: @escaping (String) -> Void
    ) {
        let navigationController = TKNavigationController()
        navigationController.configureTransparentAppearance()
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.modalTransitionStyle = .crossDissolve

        let fromViewController: UIViewController = parentRouter.rootViewController.topPresentedViewController()

        let coordinator = PasscodeInputCoordinator(
            router: NavigationControllerRouter(
                rootViewController: navigationController
            ),
            context: .confirmation,
            validator: validator,
            biometryProvider: PasscodeBiometryProvider(
                biometryProvider: BiometryProvider(),
                securityStore: securityStore
            ),
            securityStore: securityStore
        )

        coordinator.didCancel = { [weak coordinator, weak parentCoordinator] in
            fromViewController.dismiss(animated: true) {
                parentCoordinator?.removeChild(coordinator)
                onCancel()
            }
        }

        coordinator.didInputPasscode = { [weak coordinator, weak parentCoordinator] passcode in
            fromViewController.dismiss(animated: true) {
                parentCoordinator?.removeChild(coordinator)
                onInput(passcode)
            }
        }

        parentCoordinator.addChild(coordinator)
        coordinator.start()

        fromViewController.present(
            navigationController,
            animated: true
        )
    }
}

extension PasscodeInputCoordinator {
    static func getPasscode<ParentRouterViewController: UIViewController>(
        parentCoordinator: Coordinator,
        parentRouter: ContainerViewControllerRouter<ParentRouterViewController>,
        mnemonicAccess: MnemonicAccess,
        securityStore: SecurityStore
    ) async -> String? {
        await getPasscode(
            parentCoordinator: parentCoordinator,
            parentRouter: parentRouter,
            validator: PasscodeConfirmationValidator(
                mnemonicAccess: mnemonicAccess
            ),
            securityStore: securityStore
        )
    }

    static func getPasscode<ParentRouterViewController: UIViewController>(
        parentCoordinator: Coordinator,
        parentRouter: ContainerViewControllerRouter<ParentRouterViewController>,
        validator: PasscodeInputValidator,
        securityStore: SecurityStore
    ) async -> String? {
        return await Task { @MainActor in
            return await withCheckedContinuation { continuation in
                PasscodeInputCoordinator.present(
                    parentCoordinator: parentCoordinator,
                    parentRouter: parentRouter,
                    validator: validator,
                    securityStore: securityStore,
                    onCancel: {
                        continuation.resume(returning: nil)
                    },
                    onInput: {
                        continuation.resume(returning: $0)
                    }
                )
            }
        }.value
    }
}
