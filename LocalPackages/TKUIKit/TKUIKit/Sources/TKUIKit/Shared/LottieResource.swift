import Foundation

public struct LottieResource: Equatable {
    public let name: String
    public let bundle: Bundle
    public let subdirectory: String?

    public init(
        name: String,
        bundle: Bundle,
        subdirectory: String? = nil
    ) {
        self.name = name
        self.bundle = bundle
        self.subdirectory = subdirectory
    }

    public static func == (lhs: LottieResource, rhs: LottieResource) -> Bool {
        lhs.name == rhs.name
            && lhs.subdirectory == rhs.subdirectory
            && lhs.bundle.bundleURL == rhs.bundle.bundleURL
    }
}

public extension LottieResource {
    static let browser = LottieResource(
        name: "browser_tab_bar_item_lottie.json",
        bundle: .module,
        subdirectory: "Lottie"
    )

    static let collectibles = LottieResource(
        name: "collectibles_tab_bar_item_lottie.json",
        bundle: .module,
        subdirectory: "Lottie"
    )

    static let clock = LottieResource(
        name: "ic-clock_opt.json",
        bundle: .module,
        subdirectory: "Lottie"
    )

    static let diamond = LottieResource(
        name: "diamond.json",
        bundle: .module,
        subdirectory: "Lottie"
    )

    static let exclamationmarkCircle = LottieResource(
        name: "ic-exclamationmark-circle_opt.json",
        bundle: .module,
        subdirectory: "Lottie"
    )

    static let folder = LottieResource(
        name: "ic-folder_opt.json",
        bundle: .module,
        subdirectory: "Lottie"
    )

    static let magnifyingGlass = LottieResource(
        name: "ic-magnifying-glass_opt.json",
        bundle: .module,
        subdirectory: "Lottie"
    )

    static let trade = LottieResource(
        name: "trade_tab_bar_item_lottie.json",
        bundle: .module,
        subdirectory: "Lottie"
    )

    static let wallet = LottieResource(
        name: "wallet_tab_bar_item_lottie.json",
        bundle: .module,
        subdirectory: "Lottie"
    )
}
