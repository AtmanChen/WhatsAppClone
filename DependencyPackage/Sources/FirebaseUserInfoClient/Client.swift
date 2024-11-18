import Dependencies
import DependenciesMacros
import UserModels

@DependencyClient
public struct FirebaseUserInfoClient {
	public var addUserInfoListener: @Sendable (String) -> AsyncStream<UserItem?> = { _ in .never }
	public var getUser: @Sendable (String) async throws -> UserItem?
	public var updateUserItem: @Sendable (UserItem) async throws -> Void = { _ in  }
}

public protocol FirebaseUserKeyPathClientProtocol {
		associatedtype T
		var addUserKeyPathListener: @Sendable (_ uid: String, _ keyPath: String) -> AsyncStream<T?> { get }
}

@DependencyClient
public struct FirebaseUserKeyPathClient<T>: FirebaseUserKeyPathClientProtocol {
	public var addUserKeyPathListener: @Sendable (_ uid: String, _ keyPath: String) -> AsyncStream<T?> = { _, _ in .never }
}
