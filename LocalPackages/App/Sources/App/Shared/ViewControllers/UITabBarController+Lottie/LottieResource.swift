import TKUIKit

protocol LottieResourceConvertible {
    var asLottieResource: LottieResource? { get }
}

extension LottieResource: LottieResourceConvertible {
    var asLottieResource: LottieResource? {
        self
    }
}

extension MainCoordinatorStateManager.State.Tab: LottieResourceConvertible {
    var asLottieResource: LottieResource? {
        switch self {
        case .wallet:
            .wallet
        case .trade:
            .trade
        case .browser:
            .browser
        case .purchases:
            .collectibles
        case .history:
            nil
        }
    }
}
