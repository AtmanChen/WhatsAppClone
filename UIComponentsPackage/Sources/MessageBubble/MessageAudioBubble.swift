import Appearance
import ComposableArchitecture
import FirebaseUserInfoClient
import Kingfisher
import MessageModels
import SwiftUI
import UI_Extensions
import MediaPlayerView
import AVFoundation

public struct MessageAudioBubble: View {
	let messageItem: MessageItem
	let contentWidth: CGFloat
	let sliderRange: ClosedRange<Double>
	@Binding var currentTime: TimeInterval
	@Binding var isPlaying: Bool
	private var sliderValue: Binding<Double> {
		Binding(
			get: { currentTime },
			set: { newValue in
				currentTime = newValue
			}
		)
	}
	@State private var profileImageUrl: String?
	
	public init(
		messageItem: MessageItem,
		contentWidth: CGFloat,
		currentTime: Binding<TimeInterval>,
		isPlaying: Binding<Bool>
	) {
		self.messageItem = messageItem
		self.sliderRange = (0 ... (messageItem.audioDuration ?? 0.0))
		self.contentWidth = contentWidth
		self._currentTime = currentTime
		self._isPlaying = isPlaying
	}

	public var body: some View {
		let bubbleWidth = contentWidth / 1.5
		VStack(alignment: messageItem.messageHorizontalAlignment, spacing: 3) {
			HStack(alignment: .bottom) {
				profileImageView()
					.opacity(messageItem.direction == .incoming ? 1 : 0)
				HStack {
					
					playButton()
					Slider(value: sliderValue, in: sliderRange)
						.tint(.gray)
						.disabled(true)
					formatTimeInterval(messageItem.audioDuration ?? 0)
				}
				.padding(10)
				.background(Color.gray.opacity(0.1))
				.clipShape(
					RoundedRectangle(
						cornerRadius: 16,
						style: .continuous
					)
				)
				.padding(5)
				.background(messageItem.background)
				.clipShape(
					RoundedRectangle(
						cornerRadius: 16,
						style: .continuous
					)
				)
				.applyTail(messageItem.direction)
			}
			.frame(maxWidth: bubbleWidth)
			

			timestampTextView()
				.padding(.vertical, 8)
		}
		.shadow(color: Color(.systemGray3).opacity(0.1), radius: 5, x: 0, y: 20)
		.frame(maxWidth: .infinity, alignment: messageItem.messageContentAlignment)
		.task {
			Task {
				if messageItem.type.isNotAdminMessage &&
					messageItem.direction == .incoming
				{
					@Dependency(\.userInfoClient.getUser) var getUser
					if let user = try await getUser(messageItem.ownerUid) {
						profileImageUrl = user.profileImage
					}
				}
			}
		}
	}
	
	@ViewBuilder
	private func profileImageView() -> some View {
		if let profileImageUrl {
			KFImage.url(URL(string: profileImageUrl))
				.placeholder {
					Image(systemName: "person.circle.fill")
						.resizable()
				}
				.fade(duration: 0.25)
				.resizable()
				.scaledToFill()
				.clipShape(Circle())
				.frame(width: 30, height: 30)
		} else {
			Image(systemName: "person.circle.fill")
				.resizable()
				.frame(width: 30, height: 30)
		}
	}

	private func playButton() -> some View {
		Button {
			isPlaying.toggle()
		} label: {
			Image(systemName: isPlaying ? "pause.fill" : "play.fill")
				.padding(10)
				.background(messageItem.audioPlayButtonBackground)
				.clipShape(Circle())
				.foregroundStyle(messageItem.direction == .incoming ? .white : .black)
		}
	}

	@ViewBuilder
	private func timestampTextView() -> some View {
		HStack {
			Text(messageItem.messageTimestampString)
				.font(.system(size: 13))
				.foregroundStyle(.gray)
			if messageItem.direction == .outgoing {
				Appearance.Images.messageSeen
					.resizable()
					.renderingMode(.template)
					.frame(width: 15, height: 15)
					.foregroundStyle(Color(.systemBlue))
			}
		}
	}
}
