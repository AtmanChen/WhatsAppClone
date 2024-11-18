import Foundation

public enum Constant {
	public enum NotificationNames {
		static let signOutNotificationName = "com.lamberthyl.whatsappclone.signOut"
	}
	public enum Common {
		public static let pageSize: UInt = 15
	}
}

extension Notification.Name {
	public static var signOut: Notification.Name {
		Notification.Name(Constant.NotificationNames.signOutNotificationName)
	}
}
