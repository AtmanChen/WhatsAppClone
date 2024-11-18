import SwiftUI
import MessageModels
import ChannelModels
import Appearance

public struct MessageAdminTextBubble: View {
	let channel: ChannelItem
	let currentUid: String
	public init(channel: ChannelItem, currentUid: String) {
		self.channel = channel
		self.currentUid = currentUid
	}
	public var body: some View {
		VStack {
			if channel.createdBy == currentUid {
				textView("You created this group. Tap to add\n members")
			} else {
				textView("\(channel.members.first(where: { $0.uid == currentUid })!.username) created this group.")
				textView("\(channel.members.first(where: { $0.uid == currentUid })!.username) added you.")
			}
		}
	}
	
	private func textView(_ text: String) -> some View {
		Text(text)
		.multilineTextAlignment(.center)
		.font(.footnote)
		.padding(8)
		.padding(.horizontal, 5)
		.background(Appearance.Colors.bubbleWhite)
		.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
		.shadow(color: Color(.systemGray3).opacity(0.1), radius: 5, x: 0, y: 20)
	}
}

#Preview {
	MessageAdminTextBubble(channel: ChannelItem(id: "", lastMessage: "", creationDate: Date(), lastMessageTimestamp: Date(), membersCount: 2, adminUids: [], memberUids: [], members: [], createdBy: "", lastMessageType: .text), currentUid: "")
}
