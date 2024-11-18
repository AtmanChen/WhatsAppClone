import Dependencies
import DependenciesMacros
import ChannelModels
import UserModels
import MessageModels
import MediaAttachment
import Foundation

public struct MessageUploadParams {
	public let channel: ChannelItem
	public let text: String
	public let type: MessageType
	public let sender: UserItem
	public let attachment: MediaAttachment
	public init(
		channel: ChannelItem,
		text: String,
		type: MessageType,
		sender: UserItem,
		attachment: MediaAttachment
	) {
		self.channel = channel
		self.text = text
		self.type = type
		self.sender = sender
		self.attachment = attachment
	}
	
	public var thumbnailWidth: CGFloat? {
		guard type == .photo || type == .video else {
			return nil
		}
		return attachment.thumbnail?.size.width
	}
	
	public var thumbnailHeight: CGFloat? {
		guard type == .photo || type == .video else {
			return nil
		}
		return attachment.thumbnail?.size.height
	}
	public var audioDuration: TimeInterval? {
		if case let .audio(_, duration) = attachment {
			return duration
		}
		return nil
	}
}


@DependencyClient
public struct ChannelClient {
	public var createChannel: @Sendable (_ channelName: String?, _ partners: [UserItem]) async throws -> ChannelItem
	public var addChannelInfoListener: @Sendable (String) -> AsyncThrowingStream<ChannelItem?, Error> = { _ in .never }
	public var addCurrentUserChannelsListener: @Sendable () -> AsyncStream<[ChannelItem]> = { .never }
	public var sendTextMessageToChannel: @Sendable (_ channelItem: ChannelItem, _ from: UserItem, _ textMessage: String) async throws -> Void
	public var sendAttachmentsMessageToChannel: @Sendable (MessageUploadParams) async throws -> Void
	public var getMessagesOfChannel: @Sendable (_ channelId: String) -> AsyncStream<MessageItem> = { _ in .never }
}
