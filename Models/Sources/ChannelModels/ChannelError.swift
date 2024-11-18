import Foundation

public enum ChannelError: Error {
	case failedToGenerateChannelId
	case currentUserNotFound
	case failedToGenerateChannelCreatedMessageId
	case failedToGetChannelInfo
}
