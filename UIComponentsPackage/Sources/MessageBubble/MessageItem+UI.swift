
import SwiftUI
import Appearance
import MessageModels

extension MessageItem {
	public var background: Color {
		switch self.direction {
		case .outgoing:
			return Appearance.Colors.bubbleGreen
		case .incoming:
			return Appearance.Colors.bubbleWhite
		}
	}
	public var audioPlayButtonBackground: Color {
		switch self.direction {
		case .outgoing:
			return .white
		case .incoming:
			return .green
		}
	}
	public var messageHorizontalAlignment: HorizontalAlignment {
		switch self.direction {
		case .outgoing:
			return .trailing
		case .incoming:
			return .leading
		}
	}
	public var messageContentAlignment: Alignment {
		switch self.direction {
		case .outgoing:
			return .trailing
		case .incoming:
			return .leading
		}
	}
}
