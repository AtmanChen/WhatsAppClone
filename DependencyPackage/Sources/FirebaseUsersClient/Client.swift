import Dependencies
import DependenciesMacros
import UserModels

@DependencyClient
public struct FirebaseUsersClient {
	public var paginateUsers: @Sendable (_ lastCursor: String?, _ pageSize: UInt) async throws -> UserNode
}
