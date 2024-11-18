import Foundation
import DependenciesMacros
import Dependencies
import FirebaseAuth
import AuthModels

@DependencyClient
public struct FirebaseAuthClient {
	public typealias User = FirebaseAuth.User
	public var currentUser: @Sendable () -> User?
	public var addStateDidChangeListener: @Sendable () -> AsyncStream<User?> = { .never }
	public var autoLogin: @Sendable () async throws -> Void
	public var login: @Sendable (_ email: String, _ password: String) async throws -> Void
	public var createAccount: @Sendable (_ email: String, _ username: String, _ password: String) async throws -> Void
	public var logOut: @Sendable () async throws -> Void
	public var currentUserIdToken: @Sendable () async throws -> String?
}
