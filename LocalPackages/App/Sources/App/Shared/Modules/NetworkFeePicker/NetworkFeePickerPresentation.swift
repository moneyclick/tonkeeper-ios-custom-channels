import TKUIKit
import UIKit

@MainActor
public struct NetworkFeePickerPresentation {
    let configuration: NetworkFeePickerConfiguration
    let dataSource: any NetworkFeePickerDataSource
    let didSelectItem: (NetworkFeePickerItem, NetworkFeePickerCategory?) -> Void
}
