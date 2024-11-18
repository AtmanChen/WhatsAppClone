import Foundation

public enum AdminMessageType: String {
	case channelCreation
	case memberAdded
	case memberLeft
	case channelNameChanged
	public var id: Self { self } 
}
