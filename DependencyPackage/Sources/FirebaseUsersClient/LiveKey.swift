import DatabaseClient
import Dependencies
import FirebaseDatabase
import UserModels
import FirebaseAuthClient

extension FirebaseUsersClient: DependencyKey {
	public static var liveValue = FirebaseUsersClient(
		paginateUsers: { lastCursor, pageSize in
			@Dependency(\.databaseClient) var databaseClient
			let query = databaseClient.usersRef().queryOrderedByKey()
			let finalQuery: DatabaseQuery
			if let lastCursor {
				// 如果有上一页的游标，从该游标之后开始查询
				finalQuery = query.queryStarting(afterValue: lastCursor).queryLimited(toFirst: pageSize)
			} else {
				// 如果是第一页，直接限制数量
				finalQuery = query.queryLimited(toFirst: pageSize)
			}

			let snapshot = try await finalQuery.getData()
							
			guard let allObjects = snapshot.children.allObjects as? [DataSnapshot], !allObjects.isEmpty else {
				return .emptyNode
			}
			@Dependency(\.firebaseAuthClient) var firebaseAuthClient
			let users: [UserItem] = allObjects.compactMap { userSnapshot in
				if let userDict = userSnapshot.value as? [String: Any] {
					let user = UserItem(dictionary: userDict)
					if let currentUserId = firebaseAuthClient.currentUser()?.uid,
						 currentUserId == user.uid {
						return nil
					}
					return user
				}
				return nil
			}
							
			// 使用最后一个项目的键作为下一页的游标
			let nextCursor = allObjects.last?.key
							
			return UserNode(users: users, currentCursor: nextCursor)
		}
	)
}
