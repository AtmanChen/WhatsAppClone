import Foundation

public struct UserItem: Identifiable, Hashable, Codable {
	public let uid: String
	public var username: String
	public let email: String
	public var bio: String?
	public var profileImage: String?
	public init(
		uid: String,
		username: String,
		email: String,
		bio: String?,
		profileImage: String?
	) {
		self.uid = uid
		self.username = username
		self.email = email
		self.bio = bio
		self.profileImage = profileImage
	}

	public var id: String {
		uid
	}

	public var bioUnwrapped: String {
		bio ?? "Hey there! I am using WhatsApp"
	}
}

extension UserItem {
	public init(dictionary: [String: Any]) {
		self.uid = dictionary[.uid] as? String ?? ""
		self.username = dictionary[.username] as? String ?? ""
		self.email = dictionary[.email] as? String ?? ""
		self.bio = dictionary[.bio] as? String? ?? nil
		self.profileImage = dictionary[.profileImageUrl] as? String? ?? nil
	}
	public func toDictionary() -> [String: Any] {
		[
			.uid: uid,
			.username: username,
			.email: email,
			.bio: bioUnwrapped,
			.profileImageUrl: profileImage ?? ""
		]
	}
}

extension String {
	static let uid = "uid"
	static let username = "username"
	static let email = "email"
	static let bio = "bio"
	static let profileImageUrl = "profileImageUrl"
}
