import FirebaseUsersClient
import ComposableArchitecture
import UserModels
import Foundation

extension Effect {
	public static func fetchUsers(
		usersClient: FirebaseUsersClient = .liveValue,
		lastCursor: String?,
		pageSize: UInt,
		mapToAction: @escaping (UserNode) -> Action,
		errorToAction: @escaping (Error) -> Action
	) -> Effect {
		Effect.run { send in
			let userNode = try await usersClient.paginateUsers(lastCursor: lastCursor, pageSize: pageSize)
			await send(mapToAction(userNode))
		} catch: { error, send in
			await send(errorToAction(error))
		}
	}
}
