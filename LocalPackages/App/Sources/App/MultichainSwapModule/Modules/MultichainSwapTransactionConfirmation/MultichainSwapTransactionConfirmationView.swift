import SwiftUI
import TKLocalize
import TKUIKit

struct MultichainSwapTransactionConfirmationView: View {
    @ObservedObject var viewModel: MultichainSwapTransactionConfirmationViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerView
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    amountSection
                    detailsCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }

            MultichainSwapConfirmSliderRepresentable(
                title: viewModel.sliderConfirmTitle,
                isEnabled: true,
                onConfirm: viewModel.confirmSwipe
            )
            .frame(height: 88)
            .padding(16)
        }
        .background(Color(uiColor: .Background.page))
    }

    private var headerView: some View {
        DefaultModalCardHeader(
            config: .init(
                leftIcon: .init(
                    image: .TKUIKit.Icons.Size16.chevronLeft,
                    size: 16,
                    padding: 8,
                    onTap: { _ in
                        viewModel.back()
                    }
                ),
                title: .init(
                    text: TKLocales.NativeSwap.Screen.Confirm.title
                ),
                rightIcon: .close { _ in
                    viewModel.close()
                }
            )
        )
    }

    private var amountSection: some View {
        let model = viewModel.display
        return VStack(spacing: 8) {
            MultichainSwapConfirmAmountCard(
                label: TKLocales.NativeSwap.Field.send,
                amountLine: model.sendLine,
                tokenAvatarSource: model.sendTokenAvatarSource
            )

            MultichainSwapConfirmAmountCard(
                label: TKLocales.NativeSwap.Field.receive,
                amountLine: model.receiveLine,
                tokenAvatarSource: model.receiveTokenAvatarSource
            )
        }
        .overlay(alignment: .trailing) {
            SwiftUI.Image(uiImage: UIImage.TKUIKit.Icons.Size16.arrowDown)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(Color(uiColor: .Button.tertiaryForeground))
                .frame(width: 40, height: 40)
                .background(Color(uiColor: .Button.tertiaryBackground))
                .clipShape(Circle())
                .padding(.trailing, 28)
        }
    }

    private var detailsCard: some View {
        let model = viewModel.display
        return VStack(spacing: 0) {
            MultichainSwapConfirmDetailRow(
                title: "Rate",
                value: model.rateLine,
                trailingAccessory: AnyView(
                    CircularProgressRingRepresentable(
                        duration: 10,
                        onComplete: {
                            viewModel.notifyCircularProgressCompleted()
                        },
                        restartToken: viewModel.circularProgressRestartToken,
                        lineWidth: 2,
                        backgroundFillColor: UIColor.Background.content
                    )
                    .frame(width: 14, height: 14)
                )
            )
            MultichainSwapConfirmDetailRow(
                title: "Slippage",
                value: model.slippageLine,
                onInfoTap: {},
                trailingIcon: .TKUIKit.Icons.Size16.switch
            )
            MultichainSwapConfirmDetailRow(
                title: model.priceImpactTitle,
                value: model.priceImpactValue,
                onInfoTap: {}
            )
            MultichainSwapConfirmFeeRow(
                title: model.networkFeeTitle,
                value: model.networkFeeValue,
                method: model.networkFeeMethod,
                subtitle: model.networkFeeSubtitle,
                onMethodTap: viewModel.tapNetworkFeeMethod
            )
            MultichainSwapConfirmDetailRow(
                title: TKLocales.NativeSwap.Screen.Confirm.Field.provider,
                value: model.providerName,
                isLast: true
            )
        }
        .background(Color(uiColor: .Background.content))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
