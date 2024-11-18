import Appearance
import AVFoundation
import ComposableArchitecture
import FirebaseUserInfoClient
import Kingfisher
import MediaPlayerView
import MessageModels
import SwiftUI
import UIKit
import UserModels

public struct MessageImageBubble: View {
	let messageItem: MessageItem
	let contentWidth: CGFloat
	@State private var profileImageUrl: String?
	@State private var playVideo = false
	public init(messageItem: MessageItem, contentWidth: CGFloat) {
		self.messageItem = messageItem
		self.contentWidth = contentWidth
	}

	public var body: some View {
		HStack(alignment: .bottom, spacing: 6) {
			if let profileImageUrl {
				KFImage.url(URL(string: profileImageUrl))
					.placeholder {
						Image(systemName: "person.circle.fill")
							.resizable()
							.frame(width: 30, height: 30)
					}
					.fade(duration: 0.25)
					.resizable()
					.scaledToFill()
					.clipShape(Circle())
					.frame(width: 30, height: 30)
					.offset(y: 5)
			}
			messageTextView()
				.shadow(color: Color(.systemGray3).opacity(0.1), radius: 5, x: 0, y: 20)
				.overlay {
					playButton()
						.opacity(messageItem.type == .video ? 1.0 : 0.0)
				}
				.onTapGesture {
					debugPrint("didTapBubbleContent")
				}
		}
		.frame(maxWidth: .infinity, alignment: messageItem.messageContentAlignment)
		.fullScreenCover(isPresented: $playVideo) {
			if let url = messageItem.videoUrl, let playUrl = URL(string: url) {
				MediaPlayerView(player: AVPlayer(url: playUrl)) {
					playVideo = false
				}
			}
		}
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
	
	private func shareButton() -> some View {
		Image(systemName: "arrowshape.turn.up.right.fill")
			.padding()
			.foregroundStyle(.white)
			.background(Color(.systemGray3))
			.background(.thinMaterial)
			.clipShape(Circle())
	}
	
	private func messageTextView() -> some View {
		let imageWidth = min(messageItem.thumbnailWidth ?? 0, contentWidth) / 1.5
		let imageHeight = min(messageItem.thumbnailWidth ?? 0, imageWidth) * messageItem.imageHeightFactorOfWidth
		return VStack(alignment: .leading, spacing: 0) {
			KFImage.url(URL(string: messageItem.thumbnailUrl ?? ""))
				.placeholder {
					ProgressView()
				}
				.resizable()
				.scaledToFill()
				.frame(width: imageWidth, height: imageHeight)
				.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
				.background {
					RoundedRectangle(cornerRadius: 10, style: .continuous)
						.fill(Color(.systemGray5))
				}
				.overlay(
					RoundedRectangle(cornerRadius: 10, style: .continuous)
						.stroke(Color(.systemGray5))
				)
				.padding(5)
				.overlay(alignment: .bottomTrailing) {
					timestampTextView()
				}
			if !messageItem.text.isEmpty {
				Text(messageItem.text)
					.padding([.horizontal, .bottom], 8)
					.frame(maxWidth: .infinity, alignment: .leading)
					.frame(width: imageWidth)
			}
		}
		.background(messageItem.direction == .outgoing ? Appearance.Colors.bubbleGreen : Appearance.Colors.bubbleWhite)
		.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
		.applyTail(messageItem.direction)
	}
	
	private func timestampTextView() -> some View {
		HStack {
			Text(messageItem.messageTimestampString)
				.font(.system(size: 12))
			if messageItem.direction == .outgoing {
				Appearance.Images.messageSeen
					.resizable()
					.renderingMode(.template)
					.frame(width: 15, height: 15)
			}
		}
		.padding(.vertical, 2.5)
		.padding(.horizontal, 8)
		.foregroundStyle(.white)
		.background(Color(.systemGray3))
		.clipShape(Capsule())
		.padding()
	}
	
	private func playButton() -> some View {
		Button {
			playVideo = true
		} label: {
			Image(systemName: "play.fill")
				.padding()
				.imageScale(.large)
				.foregroundStyle(.gray)
				.background(.thinMaterial)
				.clipShape(Circle())
		}
	}
}

#Preview {
	Group {
		MessageImageBubble(messageItem: .init(id: "", sender: UserItem(dictionary: [:]), text: "nice message", type: .photo, ownerUid: "00", timestamp: Date(), direction: .incoming, thumbnailUrl: nil, thumbnailWidth: 0, thumbnailHeight: 0, videoUrl: nil, audioUrl: nil, audioDuration: 0), contentWidth: 0)
		MessageImageBubble(messageItem: .init(id: "", sender: UserItem(dictionary: [:]), text: "nice message", type: .photo, ownerUid: "00", timestamp: Date(), direction: .outgoing, thumbnailUrl: nil, thumbnailWidth: 0, thumbnailHeight: 0, videoUrl: nil, audioUrl: nil, audioDuration: 0), contentWidth: 0)
	}
	.fixedSize()
}
