import Dependencies
import FirebaseAuth
import Foundation
import Firebase
import UserModels
import DatabaseClient

extension FirebaseAuthClient: DependencyKey {
	public static var liveValue = FirebaseAuthClient(
		currentUser: {
			Auth.auth().currentUser
		},
		addStateDidChangeListener: {
			AsyncStream { continuation in
				Auth.auth().addStateDidChangeListener { _, user in
					continuation.yield(user)
				}
			}
		},
		autoLogin: {
			guard let currentUser = Auth.auth().currentUser else {
				throw AuthErrorCode(.nullUser)
			}
			let tokenResult = try await currentUser.getIDTokenResult(forcingRefresh: true)
			@Dependency(\.date.now) var now
			if tokenResult.expirationDate < now {
				try Auth.auth().signOut()
			}
		},
		login: { email, password in
			try await Auth.auth().signIn(withEmail: email, password: password)
		},
		createAccount: { email, username, password in
			let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
			let userItem = UserItem(uid: authResult.user.uid, username: username, email: email, bio: nil, profileImage: nil)
			@Dependency(\.databaseClient) var databaseClient
			try await databaseClient.usersRef().child(userItem.uid).setValue(userItem.toDictionary())
		},
		logOut: { try Auth.auth().signOut() },
		currentUserIdToken: {
			guard let currentUser = Auth.auth().currentUser else {
				return nil
			}
			return try await currentUser.getIDToken()
		}
	)
}
