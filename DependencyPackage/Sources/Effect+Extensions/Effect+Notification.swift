import ComposableArchitecture
import NotificationCenterClient
import Foundation

extension Effect {
	public static func listenToNotification(
		notificationCenterClient: NotificationCenterClient = .liveValue,
		notificationNames: [Notification.Name],
		mapNotificationToAction: @escaping (Notification.Name) -> Action
	) -> Self {
		.run { send in
			for await notification in notificationCenterClient.observe(notificationNames) {
				await send(mapNotificationToAction(notification.name))
			}
		}
	}
}
