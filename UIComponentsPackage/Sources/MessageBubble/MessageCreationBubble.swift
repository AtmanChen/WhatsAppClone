import SwiftUI

public struct MessageCreationBubble: View {
	@Environment(\.colorScheme) var colorScheme
	public init() {}
	public var body: some View {
		ZStack(alignment: .top) {
			(
				Text(Image(systemName: "lock.fill"))
					+
				Text(" Messages and calls are end-to-end encrypted, No one outside of this chat, not even WhatsApp, can read or listen to them.")
				+
				Text(" Learn more.")
					.bold()
			)
		}
		.font(.footnote)
		.padding(10)
		.frame(maxWidth: .infinity)
		.background((colorScheme == .dark ? Color.black : Color.yellow).opacity(0.6))
		.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
		.padding(.horizontal, 30)
	}
}

#Preview {
	MessageCreationBubble()
}
