import UserModels
import DatabaseClient
import Dependencies

extension FirebaseUserInfoClient: DependencyKey {
	public static var liveValue = FirebaseUserInfoClient(
		addUserInfoListener: { uid in
			AsyncStream { continuation in
				@Dependency(\.databaseClient) var databaseClient
				let usersRef = databaseClient.usersRef()
				let userRef = usersRef.child(uid)
				userRef.keepSynced(true)
				let handleListener = userRef.observe(.value, with: { snapshot in
					if let dict = snapshot.value as? [String: Any] {
						let user = UserItem(dictionary: dict)
						continuation.yield(user)
					}
				}, withCancel: { _ in
					//					continuation.yield(nil)
					//					continuation.finish()
				})
				continuation.onTermination = { _ in
					userRef.removeObserver(withHandle: handleListener)
				}
			}
		},
		getUser: { uid in
			@Dependency(\.databaseClient) var databaseClient
			let usersRef = databaseClient.usersRef()
			let userRef = usersRef.child(uid)
			if let userItemDict = try await userRef.getData().value as? [String: Any] {
				return UserItem(dictionary: userItemDict)
			}
			return nil
		},
//		addUserProfileImageListener: { uid in
//			AsyncStream { continuation in
//				@Dependency(\.databaseClient) var databaseClient
//				let usersRef = databaseClient.usersRef()
//				let userRef = usersRef.child(uid)
//				let userProfileImageRef = userRef.child("profileImage")
//				userProfileImageRef.keepSynced(true)
//				let handleListener = userProfileImageRef.observe(.value, with: { snapshot in
//					if let newProfileImageUrl = snapshot.value as? String {
//						continuation.yield(newProfileImageUrl)
//					}
//				}, withCancel: { _ in })
//				continuation.onTermination = { _ in
//					userProfileImageRef.removeObserver(withHandle: handleListener)
//				}
//			}
//		},
//		addUsernameListener: { uid in
//			AsyncStream { continuation in
//				@Dependency(\.databaseClient) var databaseClient
//				let usersRef = databaseClient.usersRef()
//				let userRef = usersRef.child(uid)
//				let usernameRef = userRef.child("username")
//				usernameRef.keepSynced(true)
//				let handleListener = usernameRef.observe(.value, with: { snapshot in
//					if let updatedUsername = snapshot.value as? String {
//						continuation.yield(updatedUsername)
//					}
//				}, withCancel: { _ in })
//				continuation.onTermination = { _ in
//					usernameRef.removeObserver(withHandle: handleListener)
//				}
//			}
//		},
		updateUserItem: { userItem in
			@Dependency(\.databaseClient) var databaseClient
			let usersRef = databaseClient.usersRef().child(userItem.uid)
			let userRef = usersRef.child(userItem.uid)
			userRef.setValue(userItem.toDictionary())
		}
	)
}

extension FirebaseUserKeyPathClient: DependencyKey {
	public static var liveValue: FirebaseUserKeyPathClient {
		FirebaseUserKeyPathClient(
			addUserKeyPathListener: { uid, keyPath in
				AsyncStream { continuation in
					@Dependency(\.databaseClient) var databaseClient
					let usersRef = databaseClient.usersRef()
					let userRef = usersRef.child(uid)
					let keyPathRef = userRef.child(keyPath)
					let lisenerHandle = keyPathRef.observe(.value, with: { snapshot in
						if let value = snapshot.value as? T? {
							continuation.yield(value)
						}
					})
					continuation.onTermination = { _ in
						keyPathRef.removeObserver(withHandle: lisenerHandle)
					}
				}
			}
		)
	}
}
