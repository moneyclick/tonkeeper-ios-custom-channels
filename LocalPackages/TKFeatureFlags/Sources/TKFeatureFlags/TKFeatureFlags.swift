import UIKit

public protocol TKFeatureFlags: AnyObject {
    subscript(flag: FeatureFlag) -> Bool { get set }
    func resetValue(for flag: FeatureFlag)
    func loadRemoteConfig() async

    var allValues: [FeatureFlag: FeatureFlagValue] { get }
}

public extension TKFeatureFlags {
    func asDictionary() -> [String: String] {
        allValues
            .filter { $0.value.resolvedValue }
            .reduce(into: [String: String]()) { result, entry in
                guard let remoteKey = entry.key.remoteKey else { return }
                result[remoteKey] = "true"
            }
    }
}
