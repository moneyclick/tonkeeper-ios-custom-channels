import FirebaseAnalytics
import Foundation

public final class FirebaseAnalyticsService: AnalyticsService {
    public init() {}

    public func logEvent(name: String, args: [String: Any]) {
        Analytics.logEvent(name, parameters: args)
    }
}
