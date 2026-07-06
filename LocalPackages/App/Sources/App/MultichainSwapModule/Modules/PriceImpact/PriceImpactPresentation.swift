import Foundation

@MainActor
struct PriceImpactPresentation {
    let title: String
    let subtitle: String
    let description: String
    let confirmButtonTitle: String
    let backButtonTitle: String
    let didTapClose: () -> Void
    let didTapConfirm: () -> Void
    let didTapBack: () -> Void
}
