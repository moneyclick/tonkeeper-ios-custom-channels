import KeeperCore
import SwiftUI
import TKLocalize
import TKUIKit

struct MultichainSwapView: View {
    @ObservedObject var viewModel: MultichainSwapViewModel

    @FocusState private var focusedAmountField: MultichainSwapAmountField?
    @State private var swapRotation: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            headerView
            VStack(spacing: 8) {
                sendCard
                receiveCard
            }
            .overlay(alignment: .center, content: {
                swapDirectionButton
            })
            .padding(.horizontal, 16)

            rateRow
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            Spacer()
            ButtonView(
                config: .init(
                    title: TKLocales.Actions.continueAction,
                    size: .large,
                    layoutMode: .fill,
                    appearance: .primary,
                    action: viewModel.continueSwap
                )
            )
            .disabled(!viewModel.isContinueEnabled)
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(uiColor: .Background.page))
        .task {
            focusedAmountField = .send
        }
        .onAppear {
            focusedAmountField = .send
            DispatchQueue.main.async {
                focusedAmountField = .send
            }
        }
    }

    private var headerView: some View {
        DefaultModalCardHeader(
            config: .init(
                title: .init(
                    text: TKLocales.NativeSwap.Screen.Swap.title
                ),
                rightIcon: .close { _ in
                    viewModel.close()
                }
            )
        )
    }

    private var sendCard: some View {
        MultichainSwapAmountCard(
            amount: $viewModel.sendAmount,
            balanceText: TKLocales.NativeSwap.balance(
                viewModel.sendAsset.swapFormattedBalance(amountFormatter: viewModel.amountFormatter)
            ),
            field: .send,
            focusedField: $focusedAmountField,
            tokenAvatarSource: viewModel.sendAsset.swapAvatarSource,
            tokenSymbol: viewModel.sendAsset.swapDisplaySymbol,
            network: viewModel.sendAsset.swapNetworkTag,
            onTapCard: {
                focusedAmountField = .send
            },
            onTapMax: {
                viewModel.applyMaxSend()
            },
            onTapToken: {
                viewModel.requestPickSendToken()
            }
        )
    }

    private var receiveCard: some View {
        MultichainSwapAmountCard(
            amount: $viewModel.receiveAmount,
            balanceText: nil,
            field: .receive,
            focusedField: $focusedAmountField,
            tokenAvatarSource: viewModel.receiveAsset.swapAvatarSource,
            tokenSymbol: viewModel.receiveAsset.swapDisplaySymbol,
            network: viewModel.receiveAsset.swapNetworkTag,
            onTapCard: {
                focusedAmountField = .receive
            },
            onTapMax: {},
            onTapToken: {
                viewModel.requestPickReceiveToken()
            }
        )
    }

    private var swapDirectionButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                swapRotation += .pi
                viewModel.swapTokens()
                focusedAmountField = focusedAmountField == .receive ? .send : .receive
            }

        } label: {
            SwiftUI.Image(uiImage: UIImage.TKUIKit.Icons.Size16.swapVertical)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(Color(uiColor: .Button.tertiaryForeground))
                .frame(width: 48, height: 48)
                .background(Color(uiColor: .Button.tertiaryBackground))
                .clipShape(Circle())
                .rotationEffect(.radians(swapRotation))
        }
        .buttonStyle(.plain)
    }

    private var rateRow: some View {
        HStack(spacing: 6) {
            Spacer()
            CircularProgressRingRepresentable(
                duration: 10,
                onComplete: {
                    viewModel.notifyCircularProgressCompleted()
                },
                restartToken: viewModel.circularProgressRestartToken,
                lineWidth: 2,
                backgroundFillColor: UIColor.Background.page
            )
            .frame(width: 14, height: 14)
            Text(viewModel.rateText)
                .textStyle(.body2)
                .foregroundColor(Color(uiColor: .Text.secondary))
                .lineLimit(1)
            Button(action: { viewModel.toggleRateDisplayDirection() }) {
                SwiftUI.Image(uiImage: UIImage.TKUIKit.Icons.Size16.swap)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color(uiColor: .Icon.tertiary))
            }
            .buttonStyle(.plain)
            Spacer()
        }
    }
}
