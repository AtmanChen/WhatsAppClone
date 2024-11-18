import Foundation
import Dependencies

extension DependencyValues {
	public var notificationCenter: NotificationCenterClient {
		get { self[NotificationCenterClient.self] }
		set { self[NotificationCenterClient.self] = newValue }
	}
}
