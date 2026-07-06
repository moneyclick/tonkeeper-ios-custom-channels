import SwiftUI
import TKLocalize
import TKUIKit
import UIKit

enum TokenizedAssetInfoKind {
    case stock
    case etf

    var badgeTitle: String {
        switch self {
        case .stock:
            return TKLocales.Trade.AssetDetails.Tokenized.Stock.badge
        case .etf:
            return TKLocales.Trade.AssetDetails.Tokenized.Etf.badge
        }
    }

    fileprivate var title: String {
        switch self {
        case .stock:
            return TKLocales.Trade.AssetDetails.Tokenized.Stock.title
        case .etf:
            return TKLocales.Trade.AssetDetails.Tokenized.Etf.title
        }
    }

    fileprivate var caption: String {
        switch self {
        case .stock:
            return TKLocales.Trade.AssetDetails.Tokenized.Stock.caption
        case .etf:
            return TKLocales.Trade.AssetDetails.Tokenized.Etf.caption
        }
    }

    fileprivate var bullets: [String] {
        switch self {
        case .stock:
            return [
                TKLocales.Trade.AssetDetails.Tokenized.Stock.pointOne,
                TKLocales.Trade.AssetDetails.Tokenized.Stock.pointTwo,
                TKLocales.Trade.AssetDetails.Tokenized.Stock.pointThree,
            ]
        case .etf:
            return [
                TKLocales.Trade.AssetDetails.Tokenized.Etf.pointOne,
                TKLocales.Trade.AssetDetails.Tokenized.Etf.pointTwo,
                TKLocales.Trade.AssetDetails.Tokenized.Etf.pointThree,
            ]
        }
    }
}

enum AssetInfoPopupPresenter {
    static func presentTokenized(
        kind: TokenizedAssetInfoKind,
        from viewController: UIViewController
    ) {
        present(
            content: .tokenized(kind: kind),
            from: viewController
        )
    }

    static func presentUnverifiedToken(from viewController: UIViewController) {
        present(
            content: .unverifiedToken,
            from: viewController
        )
    }

    private static func present(
        content: AssetInfoPopupContent,
        from viewController: UIViewController
    ) {
        weak var bottomSheetViewController: TKBottomSheetViewController?
        let contentViewController = AssetInfoPopupViewController(
            content: content,
            dismiss: {
                bottomSheetViewController?.dismiss()
            }
        )
        let sheetViewController = TKBottomSheetViewController(
            contentViewController: contentViewController,
            ignoreBottomSafeArea: true
        )
        bottomSheetViewController = sheetViewController

        sheetViewController.present(fromViewController: viewController)
    }
}

private struct AssetInfoPopupContent {
    let title: String
    let caption: String
    let bullets: [String]
}

private extension AssetInfoPopupContent {
    static func tokenized(kind: TokenizedAssetInfoKind) -> AssetInfoPopupContent {
        AssetInfoPopupContent(
            title: kind.title,
            caption: kind.caption,
            bullets: kind.bullets
        )
    }

    static var unverifiedToken: AssetInfoPopupContent {
        AssetInfoPopupContent(
            title: TKLocales.Token.unverified,
            caption: TKLocales.Token.UnverifiedPopup.caption,
            bullets: [
                TKLocales.Token.UnverifiedPopup.lowLiquidity,
                TKLocales.Token.UnverifiedPopup.notListed,
                TKLocales.Token.UnverifiedPopup.usedForSpam,
                TKLocales.Token.UnverifiedPopup.usedForScam,
            ]
        )
    }
}

private final class AssetInfoPopupViewController:
    UIViewController,
    TKBottomSheetContentViewController
{
    var didUpdateHeight: (() -> Void)?
    var didUpdateHeaderConfiguration: ((TKBottomSheetHeaderConfiguration?) -> Void)?

    var headerConfiguration: TKBottomSheetHeaderConfiguration? {
        TKBottomSheetHeaderConfiguration(
            title: .empty,
            contentInsets: UIEdgeInsets(
                top: 16,
                left: 16,
                bottom: 0,
                right: 16
            )
        )
    }

    private let hostingController: UIHostingController<AssetInfoPopupView>
    private var preferredWidth: CGFloat = 0

    init(
        content: AssetInfoPopupContent,
        dismiss: @escaping () -> Void
    ) {
        hostingController = UIHostingController(
            rootView: AssetInfoPopupView(
                content: content,
                dismiss: dismiss
            )
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateWidthIfNeeded(view.bounds.width, notify: true)
    }

    func calculateHeight(withWidth width: CGFloat) -> CGFloat {
        updateWidthIfNeeded(width, notify: false)

        let fittingSize = hostingController.sizeThatFits(
            in: CGSize(
                width: width,
                height: CGFloat.greatestFiniteMagnitude
            )
        ).height

        return ceil(fittingSize)
    }
}

private extension AssetInfoPopupViewController {
    func setup() {
        view.backgroundColor = .Background.page

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        hostingController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        hostingController.view.backgroundColor = .clear
        hostingController.view.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    func updateWidthIfNeeded(_ width: CGFloat, notify: Bool) {
        guard width > 0, preferredWidth != width else { return }
        preferredWidth = width
        if notify {
            didUpdateHeight?()
        }
    }
}

private struct AssetInfoPopupView: View {
    let content: AssetInfoPopupContent
    let dismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Layout.titleSpacing) {
                Text(content.title)
                    .textStyle(.h2)
                    .foregroundStyle(Color(uiColor: .Text.primary))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)

                Text(content.caption)
                    .textStyle(.body2)
                    .foregroundStyle(Color(uiColor: .Text.secondary))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, Layout.titleTopPadding)
            .padding(.horizontal, Layout.titleHorizontalInset)
            .padding(.bottom, Layout.titleBottomInset)

            VStack(spacing: 19) {
                ForEach(content.bullets.indices, id: \.self) { index in
                    AssetInfoPopupBulletRowView(text: content.bullets[index])
                }
            }
            .padding(.vertical, 21)
            .background(Color(uiColor: .Background.content))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Layout.listCornerRadius,
                    style: .continuous
                )
            )
            .padding(16)

            ButtonView(
                config: .init(
                    title: TKLocales.Actions.ok,
                    size: .large,
                    layoutMode: .fill,
                    appearance: .primary,
                    action: dismiss
                )
            )
            .padding([.top, .leading, .trailing], Layout.buttonInset)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color(uiColor: .Background.page))
    }
}

private struct AssetInfoPopupBulletRowView: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Layout.contentSpacing) {
            Text("\u{2022}")
                .textStyle(.body2)
                .foregroundStyle(Color(uiColor: .Text.primary))
                .frame(width: Layout.bulletWidth, alignment: .leading)

            Text(text)
                .textStyle(.body2)
                .foregroundStyle(Color(uiColor: .Text.primary))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, Layout.leadingInset)
        .padding(.trailing, Layout.trailingInset)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension AssetInfoPopupView {
    enum Layout {
        static let titleTopPadding: CGFloat = 1
        static let titleSpacing: CGFloat = 7
        static let titleHorizontalInset: CGFloat = 32
        static let titleBottomInset: CGFloat = 17

        static let listTopInset: CGFloat = 16
        static let listHorizontalInset: CGFloat = 16
        static let listBottomInset: CGFloat = 16
        static let listCornerRadius: CGFloat = 16

        static let buttonInset: CGFloat = 16
    }
}

private extension AssetInfoPopupBulletRowView {
    enum Layout {
        static let bulletWidth: CGFloat = 8
        static let contentSpacing: CGFloat = 5
        static let leadingInset: CGFloat = 20
        static let trailingInset: CGFloat = 16
        static let topInset: CGFloat = 21
    }
}
