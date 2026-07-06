import SwiftUI
import UIKit

public struct HintButton<Label: View, Content: View>: View {
    private let configuration: HintConfiguration
    private let content: (HintPosition.Direction?) -> Content
    private let label: () -> Label

    @StateObject private var sourceViewStore = HintSourceViewStore()

    public init(
        configuration: HintConfiguration,
        @ViewBuilder content: @escaping (HintPosition.Direction?) -> Content,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.configuration = configuration
        self.content = content
        self.label = label
    }

    public var body: some View {
        Button(action: toggleHint) {
            label()
        }
        .buttonStyle(.plain)
        .background(
            TKHintSourceViewResolver { sourceView in
                sourceViewStore.view = sourceView
            }
        )
        .onDisappear {
            HintController.dismiss(sourceView: sourceViewStore.view)
        }
    }

    private func toggleHint() {
        guard let sourceView = sourceViewStore.view else { return }

        HintController.toggle(
            sourceView: sourceView,
            configuration: configuration,
            contentViewControllerProvider: { position in
                let hostingController = UIHostingController(rootView: content(position))
                hostingController.view.backgroundColor = .clear
                hostingController.preferredContentSize = preferredContentSize(for: hostingController)
                return hostingController
            }
        )
    }

    private func preferredContentSize<Root: View>(
        for hostingController: UIHostingController<Root>
    ) -> CGSize {
        let fittingSize = hostingController.sizeThatFits(
            in: CGSize(
                width: configuration.maximumWidth,
                height: CGFloat.greatestFiniteMagnitude
            )
        )

        let width: CGFloat
        if fittingSize.width.isFinite, fittingSize.width > 0 {
            width = min(configuration.maximumWidth, ceil(fittingSize.width))
        } else {
            width = configuration.maximumWidth
        }

        return CGSize(
            width: width,
            height: ceil(fittingSize.height)
        )
    }
}
