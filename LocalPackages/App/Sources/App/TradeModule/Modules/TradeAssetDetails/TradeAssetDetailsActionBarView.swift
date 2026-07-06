import SwiftUI
import TKLocalize
import TKUIKit

struct TradeAssetDetailsActionBarView: View {
    enum State {
        case buy
        case buySell
    }

    let screen: TradeAssetDetailsScreenViewData
    let state: State
    let onBuy: () -> Void
    let onSell: () -> Void
    let onSend: () -> Void
    let onReceive: () -> Void

    @SwiftUI.State private var moreButtonAnchorView: UIView?

    init(
        screen: TradeAssetDetailsScreenViewData,
        state: State,
        onBuy: @escaping () -> Void,
        onSell: @escaping () -> Void,
        onSend: @escaping () -> Void,
        onReceive: @escaping () -> Void
    ) {
        self.screen = screen
        self.state = state
        self.onBuy = onBuy
        self.onSell = onSell
        self.onSend = onSend
        self.onReceive = onReceive
    }

    var body: some View {
        HStack(spacing: Layout.contentSpacing) {
            ButtonView(
                config: ButtonView.Config(
                    title: screen.primaryActionTitle,
                    size: .large,
                    layoutMode: .fill,
                    appearance: .primary,
                    action: onBuy
                )
            )

            if state == .buySell {
                ButtonView(
                    config: ButtonView.Config(
                        title: TKLocales.BuySellList.sell,
                        size: .large,
                        layoutMode: .fill,
                        appearance: .primary,
                        action: onSell
                    )
                )
            }

            Button {
                showMoreMenu()
            } label: {
                SwiftUI.Image(uiImage: .TKUIKit.Icons.Size28.ellipses)
                    .renderingMode(.template)
                    .foregroundStyle(Color(uiColor: .Text.primary))
                    .frame(width: Layout.moreButtonSize, height: Layout.moreButtonSize)
                    .background(
                        Circle()
                            .fill(Color(uiColor: .Button.tertiaryBackground))
                    )
            }
            .buttonStyle(.plain)
            .background(
                AnchorViewResolver { view in
                    moreButtonAnchorView = view
                }
            )
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.top, Layout.topPadding)
        .padding(.bottom, Layout.bottomPadding)
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(uiColor: .Background.page), location: 0),
                    Gradient.Stop(color: Color(uiColor: .Background.page).opacity(0.99), location: 0.0667),
                    Gradient.Stop(color: Color(uiColor: .Background.page).opacity(0.96), location: 0.1333),
                    Gradient.Stop(color: Color(uiColor: .Background.page).opacity(0.92), location: 0.2),
                    Gradient.Stop(color: Color(uiColor: .Background.page).opacity(0.85), location: 0.2667),
                    Gradient.Stop(color: Color(uiColor: .Background.page).opacity(0.77), location: 0.3333),
                    Gradient.Stop(color: Color(uiColor: .Background.page).opacity(0.67), location: 0.4),
                    Gradient.Stop(color: Color(uiColor: .Background.page).opacity(0.56), location: 0.4667),
                    Gradient.Stop(color: Color(uiColor: .Background.page).opacity(0.44), location: 0.5333),
                    Gradient.Stop(color: Color(uiColor: .Background.page).opacity(0.33), location: 0.6),
                    Gradient.Stop(color: Color(uiColor: .Background.page).opacity(0.23), location: 0.6667),
                    Gradient.Stop(color: Color(uiColor: .Background.page).opacity(0.15), location: 0.7333),
                    Gradient.Stop(color: Color(uiColor: .Background.page).opacity(0.08), location: 0.8),
                    Gradient.Stop(color: Color(uiColor: .Background.page).opacity(0.04), location: 0.8667),
                    Gradient.Stop(color: Color(uiColor: .Background.page).opacity(0.01), location: 0.9333),
                    Gradient.Stop(color: Color(uiColor: .Background.page).opacity(0), location: 1),
                ],
                startPoint: .bottom,
                endPoint: .top
            )
        )
    }

    private func showMoreMenu() {
        guard let sourceView = moreButtonAnchorView else {
            return
        }

        let items: [TKPopupMenuItem] = {
            var items: [TKPopupMenuItem] = []
            if screen.isSendAvailable {
                items.append(
                    TKPopupMenuItem(
                        title: TKLocales.WalletButtons.send,
                        icon: .TKUIKit.Icons.Size16.trayArrowUp,
                        hasSeparator: true,
                        selectionHandler: onSend
                    )
                )
            }
            items.append(
                TKPopupMenuItem(
                    title: TKLocales.WalletButtons.receive,
                    icon: .TKUIKit.Icons.Size16.qrCode,
                    selectionHandler: onReceive
                )
            )
            return items
        }()

        TKPopupMenuController.show(
            sourceView: sourceView,
            position: .topRight,
            minimumWidth: Layout.popupWidth,
            items: items,
            isSelectable: false,
            selectedIndex: nil
        )
    }
}

private extension TradeAssetDetailsActionBarView {
    enum Layout {
        static let contentSpacing: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 3
        static let moreButtonSize: CGFloat = 56
        static let cornerRadius: CGFloat = 16
        static let popupWidth: CGFloat = 200
    }
}
