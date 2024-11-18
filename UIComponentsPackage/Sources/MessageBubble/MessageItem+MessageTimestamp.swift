import MessageModels
import DateFormattClient

extension MessageItem {
	public var messageTimestampString: String {
		DateFormattClient.liveValue.timeRepresentation(self.timestamp)
	}
	public var messageHeaderTimestampString: String {
		DateFormattClient.liveValue.messageHeaderRelativeRepresentation(self.timestamp)
	}
}
