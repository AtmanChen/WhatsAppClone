import Foundation

public struct UserNode {
	public var users: [UserItem]
	public var currentCursor: String?
	public init(users: [UserItem], currentCursor: String? = nil) {
		self.users = users
		self.currentCursor = currentCursor
	}
	public static let emptyNode = UserNode(users: [], currentCursor: nil)
}
