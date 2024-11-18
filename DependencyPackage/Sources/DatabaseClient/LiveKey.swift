import FirebaseDatabase
import Dependencies
import AuthModels

private let database: Database = {
	let database = Database.database(url: "https://whatsappclone-c01d9-default-rtdb.asia-southeast1.firebasedatabase.app/")
	database.isPersistenceEnabled = true
	return database
}()

extension DatabaseClient: DependencyKey {
	public static var liveValue = DatabaseClient(
		usersRef: {
			database.reference().child("users")
		},
		channelsRef: {
			database.reference().child("channels")
		},
		messagesRef: {
			let ref = database.reference().child("channel-messages")
			return ref
		},
		userChannelsRef: {
			database.reference().child("user-channels")
		},
		userDirectChannelsRef: {
			database.reference().child("user-direct-channels")
		}
	)
}
