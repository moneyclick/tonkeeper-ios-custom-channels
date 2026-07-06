import TKUIKit

final class SettingsListDesignSystemConfigurator: SettingsListConfigurator {
    var didSelectCellsCatalog: (() -> Void)?
    var didSelectTransactionCellPreviews: (() -> Void)?
    var didSelectIconButtonViewPreviews: (() -> Void)?
    var didSelectWalletButtonPreviews: (() -> Void)?
    var didSelectBatterySwiftUIViewPreviews: (() -> Void)?
    var didSelectNotificationBannerPreviews: (() -> Void)?
    var didSelectButtonViewPreviews: (() -> Void)?
    var didSelectModalCardHeaderPreviews: (() -> Void)?
    var didSelectListTitleViewPreviews: (() -> Void)?
    var didSelectTabCategoriesViewPreviews: (() -> Void)?
    var didSelectPlaceholderViewPreviews: (() -> Void)?
    var didSelectChartPreviews: (() -> Void)?
    var didUpdateState: ((SettingsListState) -> Void)?

    var title: String {
        "Design System"
    }

    func getInitialState() -> SettingsListState {
        SettingsListState(
            sections: [
                .listItems(
                    SettingsListItemsSection(
                        items: [
                            .listItem(createCellsCatalogItem()),
                            .listItem(createTransactionCellPreviewsItem()),
                            .listItem(createButtonViewPreviewsItem()),
                            .listItem(createIconButtonViewPreviewsItem()),
                            .listItem(createWalletButtonPreviewsItem()),
                            .listItem(createBatterySwiftUIViewPreviewsItem()),
                            .listItem(createNotificationBannerPreviewsItem()),
                            .listItem(createModalCardHeaderPreviewsItem()),
                            .listItem(createListTitleViewPreviewsItem()),
                            .listItem(createTabCategoriesViewPreviewsItem()),
                            .listItem(createPlaceholderViewPreviewsItem()),
                            .listItem(createChartPreviewsItem()),
                        ],
                        headerConfiguration: SettingsListSectionHeaderView.Configuration(
                            title: "Components"
                        )
                    )
                ),
            ]
        )
    }

    private func createCellsCatalogItem() -> SettingsListItem {
        createNavigationItem(
            title: "Cells",
            id: .designSystemCellsCatalogItemIdentifier
        ) { [weak self] in
            self?.didSelectCellsCatalog?()
        }
    }

    private func createTransactionCellPreviewsItem() -> SettingsListItem {
        createNavigationItem(
            title: "Transaction Cell",
            id: .designSystemTransactionCellPreviewsItemIdentifier
        ) { [weak self] in
            self?.didSelectTransactionCellPreviews?()
        }
    }

    private func createButtonViewPreviewsItem() -> SettingsListItem {
        createNavigationItem(
            title: "Button View",
            id: .designSystemButtonViewPreviewsItemIdentifier
        ) { [weak self] in
            self?.didSelectButtonViewPreviews?()
        }
    }

    private func createIconButtonViewPreviewsItem() -> SettingsListItem {
        createNavigationItem(
            title: "Icon Button View",
            id: .designSystemIconButtonViewPreviewsItemIdentifier
        ) { [weak self] in
            self?.didSelectIconButtonViewPreviews?()
        }
    }

    private func createWalletButtonPreviewsItem() -> SettingsListItem {
        createNavigationItem(
            title: "Wallet Button",
            id: .designSystemWalletButtonPreviewsItemIdentifier
        ) { [weak self] in
            self?.didSelectWalletButtonPreviews?()
        }
    }

    private func createBatterySwiftUIViewPreviewsItem() -> SettingsListItem {
        createNavigationItem(
            title: "Battery SwiftUI View",
            id: .designSystemBatterySwiftUIViewPreviewsItemIdentifier
        ) { [weak self] in
            self?.didSelectBatterySwiftUIViewPreviews?()
        }
    }

    private func createNotificationBannerPreviewsItem() -> SettingsListItem {
        createNavigationItem(
            title: "Notification Banner",
            id: .designSystemNotificationBannerPreviewsItemIdentifier
        ) { [weak self] in
            self?.didSelectNotificationBannerPreviews?()
        }
    }

    private func createModalCardHeaderPreviewsItem() -> SettingsListItem {
        createNavigationItem(
            title: "Modal Card Header",
            id: .designSystemModalCardHeaderPreviewsItemIdentifier
        ) { [weak self] in
            self?.didSelectModalCardHeaderPreviews?()
        }
    }

    private func createListTitleViewPreviewsItem() -> SettingsListItem {
        createNavigationItem(
            title: "List Title View",
            id: .designSystemListTitleViewPreviewsItemIdentifier
        ) { [weak self] in
            self?.didSelectListTitleViewPreviews?()
        }
    }

    private func createTabCategoriesViewPreviewsItem() -> SettingsListItem {
        createNavigationItem(
            title: "Tab Categories View",
            id: .designSystemTabCategoriesViewPreviewsItemIdentifier
        ) { [weak self] in
            self?.didSelectTabCategoriesViewPreviews?()
        }
    }

    private func createPlaceholderViewPreviewsItem() -> SettingsListItem {
        createNavigationItem(
            title: "Placeholder View",
            id: .designSystemPlaceholderViewPreviewsItemIdentifier
        ) { [weak self] in
            self?.didSelectPlaceholderViewPreviews?()
        }
    }

    private func createChartPreviewsItem() -> SettingsListItem {
        createNavigationItem(
            title: "Chart",
            id: .designSystemChartPreviewsItemIdentifier
        ) { [weak self] in
            self?.didSelectChartPreviews?()
        }
    }

    private func createNavigationItem(
        title: String,
        id: String,
        onSelection: @escaping () -> Void
    ) -> SettingsListItem {
        let cellConfiguration = TKListItemCell.Configuration(
            listItemContentViewConfiguration: TKListItemContentView.Configuration(
                textContentViewConfiguration: TKListItemTextContentView.Configuration(
                    titleViewConfiguration: TKListItemTitleView.Configuration(
                        title: title
                    )
                )
            )
        )

        return SettingsListItem(
            id: id,
            cellConfiguration: cellConfiguration,
            accessory: .chevron,
            onSelection: { _ in
                onSelection()
            }
        )
    }
}

private extension String {
    static let designSystemCellsCatalogItemIdentifier = "designSystemCellsCatalogItemIdentifier"
    static let designSystemTransactionCellPreviewsItemIdentifier = "designSystemTransactionCellPreviewsItemIdentifier"
    static let designSystemIconButtonViewPreviewsItemIdentifier = "designSystemIconButtonViewPreviewsItemIdentifier"
    static let designSystemWalletButtonPreviewsItemIdentifier = "designSystemWalletButtonPreviewsItemIdentifier"
    static let designSystemBatterySwiftUIViewPreviewsItemIdentifier = "designSystemBatterySwiftUIViewPreviewsItemIdentifier"
    static let designSystemNotificationBannerPreviewsItemIdentifier = "designSystemNotificationBannerPreviewsItemIdentifier"
    static let designSystemButtonViewPreviewsItemIdentifier = "designSystemButtonViewPreviewsItemIdentifier"
    static let designSystemModalCardHeaderPreviewsItemIdentifier = "designSystemModalCardHeaderPreviewsItemIdentifier"
    static let designSystemListTitleViewPreviewsItemIdentifier = "designSystemListTitleViewPreviewsItemIdentifier"
    static let designSystemTabCategoriesViewPreviewsItemIdentifier = "designSystemTabCategoriesViewPreviewsItemIdentifier"
    static let designSystemPlaceholderViewPreviewsItemIdentifier = "designSystemPlaceholderViewPreviewsItemIdentifier"
    static let designSystemChartPreviewsItemIdentifier = "designSystemChartPreviewsItemIdentifier"
}
