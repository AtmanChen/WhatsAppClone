import Foundation
import Dependencies
import DependenciesMacros

@DependencyClient
public struct NotificationCenterClient {
	public var observe: @Sendable ([Notification.Name]) -> AsyncStream<Notification> = { _ in .never }
	public var post: @Sendable (Notification.Name, Any?, [AnyHashable: Any]?) -> Void
}
