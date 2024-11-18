import Foundation
import Dependencies

extension NotificationCenterClient: DependencyKey {
	public static var liveValue: NotificationCenterClient = Self(
		observe: { notificationNames in
			AsyncStream { continuation in
				let observer = NotificationCenter.default.addObserver(forName: nil, object: nil, queue: nil) { notification in
					if notificationNames.contains(notification.name) {
						continuation.yield(notification)
					}
				}
				continuation.onTermination = { @Sendable _ in
					NotificationCenter.default.removeObserver(observer)
				}
			}
		},
		post: { name, obj, userInfo in
			NotificationCenter.default.post(name: name, object: obj, userInfo: userInfo)
		}
	)
}
