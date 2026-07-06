import Combine
import KeeperCore
import SwiftUI
import TKLocalize
import TKUIKit
import UIKit

final class TokenPickerV2ViewController: GenericViewViewController<TokenPickerV2UiView>, TKBottomSheetDynamicScrollContentViewController {
    private enum Layout {
        static let skeletonRowCount = 8
        static let estimatedRowHeight: CGFloat = 76
        static let loadingFooterHeight: CGFloat = 56
        static let sortPopupMinimumWidth: CGFloat = 200
    }

    private let viewModel: TokenPickerV2ViewModelImplementation
    private var currentPresentation = TokenPickerV2QueryViewModel.Presentation(
        items: [],
        isLoadingMore: false,
        showsSkeleton: true,
        placeholder: nil
    )
    private var cancellables = Set<AnyCancellable>()
    private var queryViewModelCancellables = Set<AnyCancellable>()

    var scrollView: UIScrollView {
        customView.currentScrollView
    }

    var didUpdateHeight: (() -> Void)?
    var didUpdateHeaderConfiguration: ((TKBottomSheetHeaderConfiguration?) -> Void)?
    var didUpdateScrollView: ((UIScrollView) -> Void)?

    init(viewModel: TokenPickerV2ViewModelImplementation) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        bindViewModel()
        viewModel.viewDidLoad()
        setupCatalogSortOverlay()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        render()
    }

    var headerConfiguration: TKBottomSheetHeaderConfiguration? {
        TKBottomSheetHeaderConfiguration(
            title: .view {
                TokenPickerV2HeaderView(viewModel: viewModel)
            },
            rightButton: nil,
            contentInsets: .zero
        )
    }

    func calculateHeight(withWidth width: CGFloat) -> CGFloat {
        max(view.frame.height, customView.calculateHeight())
    }
}

private extension TokenPickerV2ViewController {
    enum PlaceholderKind {
        case empty(searchText: String?)
        case error
    }

    enum PlaceholderLayout {
        static let topPadding: CGFloat = 32
    }

    func configureTableView() {
        customView.tableView.register(
            SwiftUIHostingTableViewCell.self,
            forCellReuseIdentifier: String(describing: SwiftUIHostingTableViewCell.self)
        )
        customView.tableView.dataSource = self
        customView.tableView.delegate = self
        customView.tableView.separatorStyle = .none
        customView.tableView.rowHeight = UITableView.automaticDimension
        customView.tableView.estimatedRowHeight = Layout.estimatedRowHeight
        customView.tableView.showsVerticalScrollIndicator = false
        customView.tableView.contentInsetAdjustmentBehavior = .never
        customView.tableView.sectionHeaderTopPadding = 0
        customView.tableView.tableFooterView = UIView(frame: .zero)
    }

    func bindViewModel() {
        viewModel.$currentQueryViewModel
            .sink { [weak self] queryViewModel in
                self?.bind(queryViewModel: queryViewModel)
            }
            .store(in: &cancellables)

        viewModel.$tabs
            .sink { [weak self] _ in
                self?.render()
            }
            .store(in: &cancellables)
    }

    func setupCatalogSortOverlay() {
        customView.catalogSortOverlay.tapHandler = { [weak self] in
            self?.showSortPicker()
        }

        viewModel.onCatalogSortOverlayStateChanged = { [weak self] in
            self?.updateCatalogSortOverlay()
        }
        updateCatalogSortOverlay()
    }

    func updateCatalogSortOverlay() {
        customView.setCatalogSortOverlayVisible(
            viewModel.showsCatalogSortControl,
            title: viewModel.catalogSortButtonTitle
        )
        didUpdateHeight?()
    }

    func showSortPicker() {
        TKPopupMenuController.show(
            sourceView: customView.catalogSortOverlay.sortButton,
            position: .top,
            minimumWidth: Layout.sortPopupMinimumWidth,
            items: [
                TKPopupMenuItem(
                    title: TKLocales.TokensPicker.Sort.marketCap,
                    icon: nil,
                    hasSeparator: true,
                    selectionHandler: { [weak viewModel] in
                        viewModel?.selectCatalogSort(.marketCap)
                    }
                ),
                TKPopupMenuItem(
                    title: TKLocales.TokensPicker.Sort.volume,
                    icon: nil,
                    selectionHandler: { [weak viewModel] in
                        viewModel?.selectCatalogSort(.volume)
                    }
                ),
            ],
            isSelectable: true,
            selectedIndex: catalogSortSelectedIndex
        )
    }

    private var catalogSortSelectedIndex: Int? {
        switch viewModel.catalogSearchSort {
        case .marketCap:
            return 0
        case .volume:
            return 1
        }
    }

    func bind(queryViewModel: TokenPickerV2QueryViewModel?) {
        queryViewModelCancellables.removeAll()

        queryViewModel?.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else {
                    return
                }
                currentPresentation = TokenPickerV2QueryViewModel.presentation(
                    for: state
                )
                render()
                showToastIfNeeded(for: state)
            }
            .store(in: &queryViewModelCancellables)

        render()
    }

    func render() {
        switch currentPresentation.placeholder {
        case .none:
            customView.setPlaceholderVisible(false)
        case .empty:
            customView.placeholderHostingView.setContent {
                placeholderView(
                    kind: .empty(
                        searchText: normalizedSearchText
                    )
                )
            }
            customView.setPlaceholderVisible(true)
        case .error:
            customView.placeholderHostingView.setContent {
                placeholderView(
                    kind: .error
                )
            }
            customView.setPlaceholderVisible(true)
        }

        updateLoadingFooter(isVisible: currentPresentation.isLoadingMore)
        customView.tableView.reloadData()
        customView.tableView.layoutIfNeeded()
        didUpdateScrollView?(scrollView)
        didUpdateHeight?()
    }

    func placeholderView(
        kind: PlaceholderKind
    ) -> some View {
        VStack(spacing: 0) {
            PlaceholderView(
                config: placeholderConfig(for: kind)
            )
            Spacer()
        }
        .padding(.top, PlaceholderLayout.topPadding)
        .frame(maxWidth: .infinity)
    }

    func updateLoadingFooter(isVisible: Bool) {
        guard isVisible else {
            customView.tableView.tableFooterView = UIView(frame: .zero)
            return
        }

        let footerView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: customView.tableView.bounds.width,
                height: Layout.loadingFooterHeight
            )
        )
        footerView.backgroundColor = .clear

        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .Accent.blue
        indicator.startAnimating()
        footerView.addSubview(indicator)
        indicator.center = CGPoint(
            x: footerView.bounds.midX,
            y: footerView.bounds.midY
        )
        customView.tableView.tableFooterView = footerView
    }

    func retry() {
        Task {
            await viewModel.currentQueryViewModel?.refresh()
        }
    }

    var normalizedSearchText: String? {
        let trimmed = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func placeholderConfig(for kind: PlaceholderKind) -> PlaceholderView.Config {
        switch kind {
        case let .empty(searchText):
            PlaceholderView.Config(
                lottieResource: .magnifyingGlass,
                title: TKLocales.TokensPicker.Placeholder.notFoundTitle,
                subtitle: searchText.map(
                    TKLocales.TokensPicker.Placeholder.noResultsSubtitle
                )
            )
        case .error:
            PlaceholderView.Config(
                lottieResource: .exclamationmarkCircle,
                title: TKLocales.TokensPicker.Placeholder.errorTitle,
                subtitle: TKLocales.TokensPicker.Placeholder.errorSubtitle,
                button: PlaceholderView.ButtonConfig(
                    title: TKLocales.Actions.retry,
                    icon: .TKUIKit.Icons.Size16.refresh,
                    action: retry
                )
            )
        }
    }

    func showToastIfNeeded(for state: TokenPickerV2QueryViewModel.State) {
        guard case let .failed(rowData, message) = state,
              !rowData.items.isEmpty
        else {
            return
        }

        ToastPresenter.showToast(
            configuration: .defaultConfiguration(
                text: message ?? TKLocales.Trade.Assets.Errors.load
            )
        )
    }
}

extension TokenPickerV2ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if currentPresentation.showsSkeleton {
            return Layout.skeletonRowCount
        }

        return currentPresentation.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = String(describing: SwiftUIHostingTableViewCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        guard let hostingCell = cell as? SwiftUIHostingTableViewCell else {
            return cell
        }

        if currentPresentation.showsSkeleton {
            hostingCell.applyGroupedBackground(
                .init(index: indexPath.row, count: Layout.skeletonRowCount)
            )
            hostingCell.setContent(id: indexPath.row) {
                TokenPickerV2RowView(
                    content: .skeleton,
                    showsDivider: indexPath.row < Layout.skeletonRowCount - 1,
                    action: nil
                )
            }
            return hostingCell
        }

        let items = currentPresentation.items
        let item = items[indexPath.row]
        hostingCell.applyGroupedBackground(
            .init(index: indexPath.row, count: items.count)
        )
        hostingCell.setContent(id: item.id) {
            TokenPickerV2RowView(
                content: .content(item.row),
                showsDivider: indexPath.row < items.count - 1,
                action: { [weak viewModel] in
                    viewModel?.selectRow(item.id)
                }
            )
        }

        return hostingCell
    }
}

extension TokenPickerV2ViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        guard !currentPresentation.showsSkeleton,
              indexPath.row < currentPresentation.items.count
        else {
            return
        }

        let item = currentPresentation.items[indexPath.row]
        viewModel.currentQueryViewModel?.loadNextPageIfNeeded(currentItem: item)
    }
}
