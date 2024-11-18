import Dependencies

extension DependencyValues {
	public var usersClient: FirebaseUsersClient {
		get { self[FirebaseUsersClient.self] }
		set { self[FirebaseUsersClient.self] = newValue }
	}
}
