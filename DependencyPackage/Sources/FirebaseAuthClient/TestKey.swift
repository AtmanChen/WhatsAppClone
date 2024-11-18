import Dependencies

extension DependencyValues {
	public var firebaseAuthClient: FirebaseAuthClient {
		get { self[FirebaseAuthClient.self] }
		set { self[FirebaseAuthClient.self] = newValue }
	}
}
