import Foundation
import SwiftUI
import TKUIKit
import UIKit

@MainActor
protocol NetworkFeePickerDataSource {
    var content: NetworkFeePickerContent? { get }
    func loadContent() async -> NetworkFeePickerContent
}

@MainActor
protocol NetworkFeePickerItemsDataSource {
    var items: [NetworkFeePickerItem] { get }
}

@MainActor
protocol NetworkFeePickerModuleOutput: AnyObject {
    var didSelectItem: ((NetworkFeePickerItem, NetworkFeePickerCategory?) -> Void)? { get set }
    var didRequestClose: (() -> Void)? { get set }
}

@MainActor
protocol NetworkFeePickerModuleInput: AnyObject {
    func reload()
}

struct NetworkFeePickerConfiguration {
    let title: String
    let subtitle: String?

    init(
        title: String,
        subtitle: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
    }
}

enum NetworkFeePickerContent {
    case uncategorized(dataSource: any NetworkFeePickerItemsDataSource)
    case categorized(NetworkFeePickerCategoriesContent)
}

struct NetworkFeePickerCategoriesContent {
    let categories: [NetworkFeePickerCategory]
    let selectedCategoryID: NetworkFeePickerCategory.ID?

    init(
        categories: [NetworkFeePickerCategory],
        selectedCategoryID: NetworkFeePickerCategory.ID? = nil
    ) {
        self.categories = categories
        self.selectedCategoryID = selectedCategoryID
    }
}

struct NetworkFeePickerCategory: Identifiable {
    let id: String
    let title: String
    let icon: UIImage?
    let dataSource: any NetworkFeePickerItemsDataSource

    init(
        id: String,
        title: String,
        icon: UIImage? = nil,
        dataSource: any NetworkFeePickerItemsDataSource
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.dataSource = dataSource
    }
}

struct NetworkFeePickerItem: Identifiable {
    enum Leading {
        case assetAvatar(imageSource: AssetAvatarViewImageSource)
        case icon(
            image: UIImage,
            tintColor: UIColor,
            backgroundColor: UIColor
        )
    }

    enum Text {
        case singleLine(title: String)
        case titled(title: String, subtitle: String)
    }

    enum Badge {
        case accent(
            text: String,
            foreground: UIColor,
            background: UIColor
        )
    }

    let id: String
    let leading: Leading
    let text: Text
    let badge: Badge?

    init(
        id: String,
        leading: Leading,
        text: Text,
        badge: Badge? = nil
    ) {
        self.id = id
        self.leading = leading
        self.text = text
        self.badge = badge
    }
}

enum NetworkFeePickerViewState {
    case loading
    case categories(
        [NetworkFeePickerCategory],
        selectedCategoryID: NetworkFeePickerCategory.ID
    )
    case list(
        NetworkFeePickerItemsDataSource
    )
}

enum NetworkFeePickerItemsState {
    case loading
    case content([NetworkFeePickerItem])
}

@MainActor
final class NetworkFeePickerViewModelImplementation:
    ObservableObject,
    NetworkFeePickerModuleOutput,
    NetworkFeePickerModuleInput
{
    @Published private(set) var viewState: NetworkFeePickerViewState

    let configuration: NetworkFeePickerConfiguration

    var didSelectItem: ((NetworkFeePickerItem, NetworkFeePickerCategory?) -> Void)?
    var didRequestClose: (() -> Void)?

    private let dataSource: any NetworkFeePickerDataSource

    private var hasLoaded: Bool
    private var contentRequestID = 0
    private var contentTask: Task<Void, Never>?

    init(
        configuration: NetworkFeePickerConfiguration,
        dataSource: any NetworkFeePickerDataSource
    ) {
        self.configuration = configuration
        self.dataSource = dataSource
        let viewState: NetworkFeePickerViewState
        switch dataSource.content {
        case let .uncategorized(dataSource):
            viewState = .list(dataSource)
        case let .categorized(categories):
            if let firstCategory = categories.categories.first {
                let selectedCategoryId = categories.selectedCategoryID ?? firstCategory.id
                viewState = .categories(
                    categories.categories,
                    selectedCategoryID: selectedCategoryId
                )
            } else {
                viewState = .loading
            }
        case nil:
            viewState = .loading
        }
        switch viewState {
        case .loading:
            hasLoaded = false
        default:
            hasLoaded = true
        }
        self.viewState = viewState
    }

    deinit {
        contentTask?.cancel()
    }

    var modalHeaderConfiguration: TKBottomSheetHeaderConfiguration {
        TKBottomSheetHeaderConfiguration(
            title: .title(
                title: configuration.title,
                subtitle: configuration.subtitle
            ),
            rightButton: .close(),
            contentInsets: UIEdgeInsets(
                top: 19,
                left: 16,
                bottom: 19,
                right: 16
            )
        )
    }

    func viewDidLoad() {
        guard !hasLoaded else {
            return
        }

        hasLoaded = true
        reload()
    }

    func reload() {
        contentTask?.cancel()

        contentRequestID += 1
        let requestID = contentRequestID

        viewState = .loading

        contentTask = Task { [weak self] in
            guard let self else {
                return
            }

            let content = await dataSource.loadContent()
            guard !Task.isCancelled, requestID == contentRequestID else {
                return
            }

            apply(content: content)
        }
    }

    func close() {
        contentTask?.cancel()
        didRequestClose?()
    }

    func selectCategory(_ categoryID: NetworkFeePickerCategory.ID) {
        guard
            case let .categories(categories, selectedCategoryID) = viewState,
            selectedCategoryID != categoryID,
            categories.map(\.id).contains(categoryID)
        else {
            return
        }
        viewState = .categories(
            categories,
            selectedCategoryID: categoryID
        )
    }

    func selectItem(_ item: NetworkFeePickerItem) {
        didSelectItem?(item, selectedCategory)
        didRequestClose?()
    }
}

private extension NetworkFeePickerViewModelImplementation {
    var selectedCategory: NetworkFeePickerCategory? {
        guard case let .categories(categories, selectedCategoryID) = viewState else {
            return nil
        }
        return categories.first(where: { $0.id == selectedCategoryID })
    }

    func apply(content: NetworkFeePickerContent) {
        switch content {
        case let .uncategorized(dataSource):
            viewState = .list(dataSource)
        case let .categorized(content):
            guard !content.categories.isEmpty else {
                viewState = .categories([], selectedCategoryID: "")
                return
            }
            let fallbackSelectedCategory = content.categories[0].id
            let selectedCategoryId = content
                .selectedCategoryID
                .flatMap {
                    content.categories
                        .map(\.id)
                        .contains($0) ? $0 : fallbackSelectedCategory
                } ?? fallbackSelectedCategory
            viewState = .categories(
                content.categories,
                selectedCategoryID: selectedCategoryId
            )
        }
    }
}
