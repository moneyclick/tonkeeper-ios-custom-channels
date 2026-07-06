import SwiftUI
import TKLocalize
import TKUIKit

enum MultichainSwapAmountField: Hashable {
    case send
    case receive

    var title: String {
        switch self {
        case .receive: return TKLocales.NativeSwap.Field.receive
        case .send: return TKLocales.NativeSwap.Field.send
        }
    }
}

struct MultichainSwapAmountCard: View {
    @Binding var amount: String

    let balanceText: String?
    let field: MultichainSwapAmountField
    var focusedField: FocusState<MultichainSwapAmountField?>.Binding
    let tokenAvatarSource: AssetAvatarViewImageSource
    let tokenSymbol: String
    let network: String?

    let onTapCard: () -> Void
    let onTapMax: () -> Void
    let onTapToken: () -> Void

    private var isFocused: Bool {
        let focus = focusedField.wrappedValue
        if focus == nil {
            return field == .send
        }
        return focus == field
    }

    private var fieldState: TKTextFieldState {
        isFocused ? .active : .inactive
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text(field.title)
                    .textStyle(.body2)
                    .foregroundColor(Color(uiColor: .Text.secondary))
                Spacer(minLength: 8)
                if let balanceText {
                    HStack(spacing: 8) {
                        Text(balanceText)
                            .textStyle(.body2)
                            .foregroundColor(Color(uiColor: .Text.secondary))
                        if field == .send {
                            Button(action: onTapMax) {
                                Text(TKLocales.Common.Numbers.max)
                                    .textStyle(.label2)
                                    .foregroundColor(Color(uiColor: .Accent.blue))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)

            HStack(alignment: .center, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    TextField("0", text: $amount)
                        .font(Font(TKTextStyle.num2.font))
                        .foregroundColor(Color(uiColor: .Text.primary))
                        .tint(Color(uiColor: .Accent.blue))
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled()
                        .focused(focusedField, equals: field)
                        .disabled(field != .send)
                        .onChange(of: amount) { newValue in
                            let normalized = MultichainSwapAmountCard.normalizeDecimalInput(newValue)
                            if normalized != newValue {
                                amount = normalized
                            }
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                MultichainSwapTokenPickerCapsule(
                    imageSource: tokenAvatarSource,
                    symbol: tokenSymbol,
                    network: network,
                    action: onTapToken
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .background(Color(uiColor: fieldState.backgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(uiColor: fieldState.borderColor), lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTapCard()
        }
    }
}

private extension MultichainSwapAmountCard {
    static func normalizeDecimalInput(_ raw: String) -> String {
        let raw = raw.replacingOccurrences(of: ",", with: ".")
        var result = ""
        var hasDecimalSeparator = false

        for character in raw where character.isASCII {
            if character.isNumber {
                result.append(character)
            } else if character == "." && !hasDecimalSeparator {
                result.append(character)
                hasDecimalSeparator = true
            }
        }

        if result == "." {
            return "0."
        }
        if result.first == "." && !result.dropFirst().contains(".") {
            return "0" + result
        }

        return result
    }
}
