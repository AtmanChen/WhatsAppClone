import Foundation
import UserModels
import Tagged
import MessageModels

public struct ChannelItem: Identifiable, Equatable, Hashable {
	public var id: String
	public var name: String?
	public var lastMessage: String
	public var creationDate: Date
	public var lastMessageTimestamp: Date
	public var membersCount: UInt
	public var adminUids: [String]
	public var memberUids: [String]
	public var members: [UserItem]
	public var thumbnailUrl: String?
	public var createdBy: String
	public let lastMessageType: MessageType
	
	public init(
		id: String,
		name: String? = nil,
		lastMessage: String,
		creationDate: Date,
		lastMessageTimestamp: Date,
		membersCount: UInt,
		adminUids: [String],
		memberUids: [String],
		members: [UserItem],
		thumbnailUrl: String? = nil,
		createdBy: String,
		lastMessageType: MessageType
	) {
		self.id = id
		self.name = name
		self.lastMessage = lastMessage
		self.creationDate = creationDate
		self.lastMessageTimestamp = lastMessageTimestamp
		self.membersCount = membersCount
		self.adminUids = adminUids
		self.memberUids = memberUids
		self.members = members
		self.thumbnailUrl = thumbnailUrl
		self.createdBy = createdBy
		self.lastMessageType = lastMessageType
	}
	
	public var previewMessage: String {
		switch lastMessageType {
		case .admin:
			return "Newly Created Chat!"
		case .text:
			return lastMessage
		case .photo:
			return "Photo Message"
		case .video:
			return "Video Message"
		case .audio:
			return "Audio Message"
		}
	}
	
	public var isGroupChat: Bool {
		membersCount > 2
	}
	public static let placeholder = ChannelItem(
		id: "1",
		lastMessage: "Hello World",
		creationDate: Date(),
		lastMessageTimestamp: Date(),
		membersCount: 2,
		adminUids: [],
		memberUids: [],
		members: [],
		createdBy: "001",
		lastMessageType: MessageType.photo
	)
}

extension ChannelItem {
	public init(from dict: [String: Any]) {
		self.id = dict["id"] as? String ?? ""
		self.name = (dict[.channelNameKey] as? String) ?? nil
		self.lastMessage = dict[.channelLastMessageKey] as? String ?? ""
		let creationInterval = dict[.channelCreationDateKey] as? Double ?? 0
		self.creationDate = Date(timeIntervalSince1970: creationInterval)
		let lastMessageTimeStampInterval = dict[.channelLastMessageTimestampKey] as? Double ?? 0
		self.lastMessageTimestamp = Date(timeIntervalSince1970: lastMessageTimeStampInterval)
		self.membersCount = dict[.channelMembersCountKey] as? UInt ?? 0
		self.adminUids = dict[.channelAdminUidsKey] as? [String] ?? []
		self.thumbnailUrl = dict[.channelThumbnailUrlKey] as? String ?? nil
		self.memberUids = dict[.channelMemberUidsKey] as? [String] ?? []
//		self.members = dict[.channelMembersKey] as? [UserItem] ?? []
		let membersDict = dict[.channelMembersKey] as? [[String: Any]] ?? []
		self.members = membersDict.map { UserItem(dictionary: $0) }
		self.createdBy = dict[.channelCreatedByKey] as? String ?? ""
		self.lastMessageType = MessageType.typeFrom(dict["lastMessageType"] as? String ?? "text") ?? .text
	}
}

extension String {
	public static let channelNameKey = "name"
	public static let channelLastMessageKey = "lastMessage"
	public static let channelCreationDateKey = "creationDate"
	public static let channelLastMessageTimestampKey = "lastMessageTimestamp"
	public static let channelMembersCountKey = "membersCount"
	public static let channelAdminUidsKey = "adminUids"
	public static let channelMemberUidsKey = "memberUids"
	public static let channelThumbnailUrlKey = "thumbnailUrl"
	public static let channelMembersKey = "members"
	public static let channelCreatedByKey = "createdBy"
}
