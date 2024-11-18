import SwiftUI
import MessageModels
import ChannelModels
import Appearance
import UserModels

public struct MessageBubbleView: View {
	let message: MessageItem
	let channel: ChannelItem
	let contentWidth: CGFloat
	let currentUserId: String
	let isNewDay: Bool
	let showSender: Bool
	@Binding var audioPlayCurrentTime: TimeInterval
	@Binding var audioPlayPlaying: Bool
	public init(
		message: MessageItem,
		channel: ChannelItem,
		contentWidth: CGFloat,
		currentUserId: String,
		isNewDay: Bool,
		showSender: Bool,
		audioPlayCurrentTime: Binding<TimeInterval>,
		audioPlayPlaying: Binding<Bool>
	) {
		self.message = message
		self.channel = channel
		self.contentWidth = contentWidth
		self.currentUserId = currentUserId
		self.isNewDay = isNewDay
		self.showSender = showSender
		self._audioPlayCurrentTime = audioPlayCurrentTime
		self._audioPlayPlaying = audioPlayPlaying
	}
	public var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			if isNewDay {
				newDayTimeStampTextView()
					.padding(.vertical)
			}
			if showSender {
				messageSenderNameTextView()
			}
			composeDynamicBubbleView()
		}
	}
	
	@ViewBuilder
	private func composeDynamicBubbleView() -> some View {
		switch message.type {
		case .text:
			MessageTextBubbleView(messageItem: message)
		case .photo,
				 .video:
			MessageImageBubble(messageItem: message, contentWidth: contentWidth)

		case .audio:
			MessageAudioBubble(
				messageItem: message,
				contentWidth: contentWidth,
				currentTime: $audioPlayCurrentTime,
				isPlaying: $audioPlayPlaying
			)
			.tag(message.id)
		case let .admin(adminType):
			switch adminType {
			case .channelCreation:
				newDayTimeStampTextView()
				MessageCreationBubble()
					.frame(maxWidth: .infinity)
					.padding()
				if channel.isGroupChat {
					MessageAdminTextBubble(channel: channel, currentUid: currentUserId)
						.frame(maxWidth: .infinity)
				}

			default:
				Text("ADMIN TEXT")
			}
		}
	}
	
	private func newDayTimeStampTextView() -> some View {
		Text(message.messageHeaderTimestampString)
			.font(.caption)
			.bold()
			.padding(.vertical, 3)
			.padding(.horizontal)
			.background(Appearance.Colors.whatsAppGrey)
			.clipShape(Capsule())
			.frame(maxWidth: .infinity)
	}
	
	private func messageSenderNameTextView() -> some View {
		Text(message.sender.username)
			.lineLimit(1)
			.foregroundStyle(.gray)
			.font(.footnote)
			.padding(.bottom, 2)
			.padding(.horizontal)
			.padding(.leading, 20)
	}
}
