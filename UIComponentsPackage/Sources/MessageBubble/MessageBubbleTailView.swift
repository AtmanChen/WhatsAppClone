import Appearance
import MessageModels
import SwiftUI

public struct MessageBubbleTailView: View {
	let direction: MessageDirection
	public init(direction: MessageDirection) {
		self.direction = direction
	}

	public var body: some View {
		Group {
			if self.direction == .outgoing {
				Appearance.Images.messageOutgoingTail
					.renderingMode(.template)
					.resizable()
					.frame(width: 10, height: 10)
					.offset(y: 3)
					.foregroundStyle(Appearance.Colors.bubbleGreen)
			} else {
				Appearance.Images.messageIncomingTail
					.renderingMode(.template)
					.resizable()
					.frame(width: 10, height: 10)
					.offset(y: 3)
					.foregroundStyle(Appearance.Colors.bubbleWhite)
			}
		}
	}
}

public struct MessageBubbleTailModifier: ViewModifier {
	let direction: MessageDirection
	public init(direction: MessageDirection) {
		self.direction = direction
	}

	public func body(content: Content) -> some View {
		content
			.overlay(alignment: direction == .incoming ? .bottomLeading : .bottomTrailing) {
				MessageBubbleTailView(direction: direction)
			}
	}
}

public extension View {
	func applyTail(_ direction: MessageDirection) -> some View {
		modifier(MessageBubbleTailModifier(direction: direction))
	}
}
