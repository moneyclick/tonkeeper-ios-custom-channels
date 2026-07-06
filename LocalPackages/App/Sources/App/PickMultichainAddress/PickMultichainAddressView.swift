import SwiftUI
import TKUIKit

struct PickMultichainAddressView: View {
    @ObservedObject var viewModel: PickMultichainAddressViewModelImplementation

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                PickMultichainAddressRowView(
                    item: item,
                    isSelected: item.address == viewModel.selectedAddress,
                    onSelect: { viewModel.selectAddress(item.address) },
                    onCopy: { viewModel.copyAddress(item.address) },
                    showDivider: index < viewModel.items.count - 1
                )
            }
        }
        .asCellsGroup()
        .padding(.top, PickMultichainAddressPresentation.contentVerticalPadding)
    }
}

struct PickMultichainAddressRowView: View {
    let item: PickMultichainAddressItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onCopy: () -> Void
    let showDivider: Bool

    var body: some View {
        Cell(
            config: .init(
                style: .grouped,
                showsDivider: showDivider
            ),
            leading: {
                CellAssetLeading {
                    AssetAvatarView(
                        imageSource: .image(item.icon)
                    )
                }
            },
            center: {
                CellCenter(
                    primaryRow: CellCenterPrimaryRow(
                        config: .content(
                            .init(
                                title: item.title
                            )
                        )
                    ),
                    secondaryRow: CellCenterSecondaryRow(
                        config: .content(
                            .init(
                                value: .init(
                                    title: item.shortAddress
                                )
                            )
                        )
                    )
                )
            },
            trailing: {
                HStack(alignment: .center, spacing: 0) {
                    Button(action: onSelect) {
                        CellTrailingAccessory(
                            config: .init(
                                color: .Icon.primary,
                                icon: .init(
                                    uiImage: .TKUIKit.Icons.Size28.qrCodeAlternate
                                )
                            )
                        )
                    }
                    .buttonStyle(.plain)

                    Button(action: onCopy) {
                        CellTrailingAccessory(
                            config: .init(
                                color: .Icon.primary,
                                icon: .init(
                                    uiImage: .TKUIKit.Icons.Size28.copyOutline
                                )
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        )
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(
                cornerRadius: PickMultichainAddressPresentation.rowHighlightCornerRadius,
                style: .continuous
            )
            .fill(isSelected ? Color(uiColor: .Background.highlighted) : Color.clear)
            .padding(.horizontal, PickMultichainAddressPresentation.rowHighlightHorizontalInset)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}
