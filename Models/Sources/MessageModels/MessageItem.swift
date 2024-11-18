import Foundation
import Tagged
import UserModels

public enum MessageType: Equatable, Hashable {
	case admin(AdminMessageType), text, photo, video, audio
	public var id: Self { self }
	public var title: String {
		switch self {
		case .admin: return "admin"
		case .text: return "text"
		case .photo: return "photo"
		case .video: return "video"
		case .audio: return "audio"
		}
	}
	public static func typeFrom(_ string: String) -> MessageType? {
		switch string {
		case "text": return .text
		case "photo": return .photo
		case "video": return .video
		case "audio": return .audio
		default:
			if let adminMessageType = AdminMessageType(rawValue: string) {
				return .admin(adminMessageType)
			} else {
				return nil
			}
		}
	}
	public static func ==(lhs: MessageType, rhs: MessageType) -> Bool {
		switch (lhs, rhs) {
		case (.admin, .admin):
			return true
		case (.text, .text):
			return true
		case (.photo, .photo):
			return true
		case (.video, .video):
			return true
		case (.audio, .audio):
			return true
		default: return false
		}
	}
	public var isNotAdminMessage: Bool {
		self == .audio ||
		self == .photo ||
		self == .text ||
		self == .video
	}
	public var iconName: String {
		switch self {
		case .admin:
			return "megaphone.fill"
		case .text:
			return ""
		case .photo:
			return "photo.fill"
		case .video:
			return "video.fill"
		case .audio:
			return "mic.fill"
		}
	}
}

public enum MessageDirection: Identifiable, Codable, CaseIterable {
	case outgoing
	case incoming
	
	#if DEBUG
	public static var random: MessageDirection {
		allCases.randomElement()!
	}
	#endif
	public var id: Self { self }
}

public struct MessageItem: Identifiable, Hashable, Equatable {
	public let id: String
	public let sender: UserItem
	public let text: String
	public let type: MessageType
	public let ownerUid: String
	public let timestamp: Date
	public let direction: MessageDirection
	public let thumbnailUrl: String?
	public let thumbnailWidth: CGFloat?
	public let thumbnailHeight: CGFloat?
	public let videoUrl: String?
	public let audioUrl: String?
	public let audioDuration: TimeInterval?
	public init(
		id: String,
		sender: UserItem,
		text: String,
		type: MessageType,
		ownerUid: String,
		timestamp: Date,
		direction: MessageDirection,
		thumbnailUrl: String?,
		thumbnailWidth: CGFloat?,
		thumbnailHeight: CGFloat?,
		videoUrl: String?,
		audioUrl: String?,
		audioDuration: TimeInterval?
	) {
		self.id = id
		self.sender = sender
		self.text = text
		self.type = type
		self.ownerUid = ownerUid
		self.timestamp = timestamp
		self.direction = direction
		self.thumbnailUrl = thumbnailUrl
		self.thumbnailWidth = thumbnailWidth
		self.thumbnailHeight = thumbnailHeight
		self.videoUrl = videoUrl
		self.audioUrl = audioUrl
		self.audioDuration = audioDuration
	}
	public static func ==(lhs: MessageItem, rhs: MessageItem) -> Bool {
		lhs.id == rhs.id
	}
	public var imageHeightFactorOfWidth: CGFloat {
		if let thumbnailWidth, let thumbnailHeight {
			return thumbnailHeight / thumbnailWidth
		}
		return 1
	}
}

extension MessageItem {
	public init(id: String, currentUid: String, dict: [String: Any]) {
		self.id = id
		self.text = dict["text"] as? String ?? ""
		self.type = MessageType.typeFrom(dict["type"] as? String ?? "text") ?? .text
		let ownerUid = dict["ownerUid"] as? String ?? ""
		self.ownerUid = ownerUid
		self.direction = currentUid == ownerUid ? .outgoing : .incoming
		self.timestamp = Date(timeIntervalSince1970: dict["timestamp"] as? Double ?? 0)
		self.thumbnailUrl = dict["thumbnailUrl"] as? String
		self.thumbnailWidth = dict["thumbnailWidth"] as? CGFloat
		self.thumbnailHeight = dict["thumbnailHeight"] as? CGFloat
		self.videoUrl = dict["videoUrl"] as? String
		self.audioDuration = dict["audioDuration"] as? TimeInterval
		self.audioUrl = dict["audioUrl"] as? String
		if let senderData = (dict["sender"] as? String ?? "").data(using: .utf8) {
			self.sender = (try? JSONDecoder().decode(UserItem.self, from: senderData)) ?? UserItem(dictionary: [:])
		} else {
			self.sender = UserItem(dictionary: [:])
		}
	}
}
