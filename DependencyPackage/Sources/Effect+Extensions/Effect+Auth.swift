import ComposableArchitecture
import FirebaseAuthClient

extension Effect {
	public static func listenToUserState(
		firebaseAuthClient: FirebaseAuthClient = .liveValue,
		mapUserToAction: @escaping (FirebaseAuthClient.User?) -> Action
	) -> Self {
		.run { send in
			for await user in firebaseAuthClient.addStateDidChangeListener() {
				await send(mapUserToAction(user))
			}
		}
	}
}
