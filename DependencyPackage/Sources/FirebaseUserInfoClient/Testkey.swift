import Dependencies


extension DependencyValues {
	public var userInfoClient: FirebaseUserInfoClient {
		get { self[FirebaseUserInfoClient.self] }
		set { self[FirebaseUserInfoClient.self] = newValue }
	}
}

private enum UserNameClientKey: DependencyKey {
		static let liveValue = FirebaseUserKeyPathClient<String>.liveValue
}

private enum UserProfileImageClientKey: DependencyKey {
		static let liveValue = FirebaseUserKeyPathClient<String>.liveValue
}

private enum UserBioClientKey: DependencyKey {
		static let liveValue = FirebaseUserKeyPathClient<String>.liveValue
}

extension DependencyValues {
	public var userNameClient: FirebaseUserKeyPathClient<String> {
		get { self[UserNameClientKey.self] }
		set { self[UserNameClientKey.self] = newValue }
	}
	public var userProfileImageClient: FirebaseUserKeyPathClient<String> {
		get { self[UserProfileImageClientKey.self] }
		set { self[UserProfileImageClientKey.self] = newValue }
	}
	public var userBioClient: FirebaseUserKeyPathClient<String> {
		get { self[UserBioClientKey.self] }
		set { self[UserBioClientKey.self] = newValue }
	}
}
