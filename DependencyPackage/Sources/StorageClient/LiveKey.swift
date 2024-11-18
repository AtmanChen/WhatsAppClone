import Foundation
import FirebaseStorage
import Dependencies

private let storage: FirebaseStorage.Storage = {
//	let database = Database.database(url: "https://whatsappclone-c01d9-default-rtdb.asia-southeast1.firebasedatabase.app/")
//	database.isPersistenceEnabled = true
//	return database
	let storage = FirebaseStorage.Storage.storage(url: "gs://whatsappclone-c01d9.appspot.com/")
	return storage
}()

extension StorageClient: DependencyKey {
	public static var liveValue = StorageClient(
		storageRef: {
			storage.reference()
		},
		profileImageRef: {
			storage.reference().child("profile_image_urls")
		},
		photoMessagesRef: {
			storage.reference().child("photo_messages")
		},
		videoMessagesRef: {
			storage.reference().child("video_messages")
		},
		audioMessagesRef: {
			storage.reference().child("audio_messages")
		}
	)
}

