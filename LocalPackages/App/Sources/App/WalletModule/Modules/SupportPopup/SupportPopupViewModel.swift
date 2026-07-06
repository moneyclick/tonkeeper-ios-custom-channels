import Foundation
import KeeperCore
import TKCore
import TKLocalize
import TKUIKit
import TonSwift
import TronSwift
import UIKit

@MainActor
public protocol SupportPopupModuleOutput: AnyObject {
    var didOpenURL: ((URL) -> Void)? { get set }
}

@MainActor
protocol SupportPopupViewModel: AnyObject {
    var didUpdateConfiguration: ((TKPopUp.Configuration) -> Void)? { get set }

    func viewDidLoad()
}

@MainActor
final class SupportPopupViewModelImplementation: SupportPopupViewModel, SupportPopupModuleOutput {
    // MARK: - SupportPopupViewModel

    var didUpdateConfiguration: ((TKPopUp.Configuration) -> Void)?
    var didOpenURL: ((URL) -> Void)?

    // MARK: - Dependencies

    private let directSupportURL: URL?
    private let supportEmailURL: URL?

    init(
        directSupportURL: URL?,
        supportEmailURL: URL?
    ) {
        self.directSupportURL = directSupportURL
        self.supportEmailURL = supportEmailURL
    }

    func viewDidLoad() {
        prepareContent()
    }

    private func prepareContent() {
        let askAction = { [weak self] in
            guard let self, let directSupportURL else { return }

            didOpenURL?(directSupportURL)
        }

        let emailAction = { [weak self] in
            guard let self, let supportEmailURL else { return }

            didOpenURL?(supportEmailURL)
        }

        let askButtonConfiguration = makeButtonConfiguration(
            category: .primary,
            title: TKLocales.Support.SupportPopup.Buttons.ask,
            icon: .TKUIKit.Icons.Size16.telegram,
            action: askAction
        )

        let emailButtonConfiguration = makeButtonConfiguration(
            category: .secondary,
            title: TKLocales.Support.SupportPopup.Buttons.email,
            icon: .TKUIKit.Icons.Size16.envelope,
            action: emailAction
        )

        let configuration = TKPopUp.Configuration(
            items: [
                SupportPopupImagePopUpItem(
                    configuration: SupportPopupImageView.Configuration(
                        image: .TKUIKit.Icons.Size28.messageBubble
                    ),
                    bottomSpace: 20
                ),
                TKPopUp.Component.TitleCaption(
                    title: TKLocales.Support.SupportPopup.title,
                    caption: TKLocales.Support.SupportPopup.caption,
                    bottomSpace: 0
                ),
                TKPopUp.Component.ButtonGroupComponent(
                    buttons: [
                        TKPopUp.Component.ButtonComponent(
                            buttonConfiguration: askButtonConfiguration
                        ),
                        TKPopUp.Component.ButtonComponent(
                            buttonConfiguration: emailButtonConfiguration
                        ),
                    ]
                ),
            ]
        )

        didUpdateConfiguration?(configuration)
    }

    private func makeButtonConfiguration(
        category: TKActionButtonCategory,
        title: String,
        icon: UIImage?,
        action: @escaping () -> Void
    ) -> TKButton.Configuration {
        var configuration = TKButton.Configuration.actionButtonConfiguration(
            category: category,
            size: .large
        )
        configuration.content = TKButton.Configuration.Content(
            title: .plainString(title),
            icon: icon
        )
        configuration.action = action
        return configuration
    }
}
