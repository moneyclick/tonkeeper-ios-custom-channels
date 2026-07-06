import SwiftUI
import UIKit

public struct ChartErrorContentView: View {
    private let title: String?
    private let subtitle: String?

    public init(
        title: String?,
        subtitle: String?
    ) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let title, !title.isEmpty {
                Text(title)
                    .textStyle(.label1)
                    .foregroundStyle(Color(uiColor: .Text.primary))
                    .multilineTextAlignment(.center)
            }

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .textStyle(.body2)
                    .foregroundStyle(Color(uiColor: .Text.secondary))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
