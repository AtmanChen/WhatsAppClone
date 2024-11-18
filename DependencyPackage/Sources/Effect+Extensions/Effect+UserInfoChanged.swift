import ComposableArchitecture
import FirebaseUserInfoClient
import UserModels
import Dependencies

extension Effect {
	public static func listenToUserInfo(
		firebaseUserInfoClient: FirebaseUserInfoClient = .liveValue,
		uid: String,
		mapToAction: @escaping (UserItem?) -> Action
	) -> Effect {
		.run { send in
			for await userItem in firebaseUserInfoClient.addUserInfoListener(uid) {
				await send(mapToAction(userItem))
			}
		}
	}
	public static func listenToUserProfileImage(
		uid: String,
		mapToAction: @escaping (String) -> Action
	) -> Effect {
		.run { send in
			@Dependency(\.userProfileImageClient) var userProfileImageClient
			for await updatedProfileImage in userProfileImageClient.addUserKeyPathListener(uid, "profileImageUrl") {
				await send(mapToAction(updatedProfileImage ?? ""))
			}
		}
	}
	public static func listenToUsername(
		uid: String,
		mapToAction: @escaping (String) -> Action
	) -> Effect {
		.run { send in
			@Dependency(\.userNameClient) var userNameClient
			for await updatedUsername in userNameClient.addUserKeyPathListener(uid, "username") {
				await send(mapToAction(updatedUsername ?? ""))
			}
		}
	}
	public static func listenToUserBio(
		uid: String,
		mapToAction: @escaping (String) -> Action
	) -> Effect {
		.run { send in
			@Dependency(\.userBioClient) var userBioClient
			for await updatedBio in userBioClient.addUserKeyPathListener(uid, "bio") {
				await send(mapToAction(updatedBio ?? ""))
			}
		}
	}
}
