import Appearance
import ComposableArchitecture
import DateFormattClient
import FirebaseUserInfoClient
import Kingfisher
import MessageModels
import SwiftUI
import UserUIComponents

public struct MessageTextBubbleView: View {
	let messageItem: MessageItem
	@State private var profileImageUrl: String?
	public init(messageItem: MessageItem) {
		self.messageItem = messageItem
	}

	public var body: some View {
		HStack(alignment: .bottom, spacing: 6) {
			profileImageView()
				.opacity(messageItem.direction == .outgoing ? 0 : 1)
			if messageItem.direction == .outgoing {
				Spacer()
				timestampTextView()
			}
			messageContent()
			if messageItem.direction == .incoming {
				timestampTextView()
			}
		}
		.shadow(color: Color(.systemGray3).opacity(0.1), radius: 5, x: 0, y: 20)
		.frame(maxWidth: .infinity, alignment: messageItem.direction == .incoming ? .leading : .trailing)
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
						.frame(width: 30, height: 30)
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

	@ViewBuilder
	private func messageContent() -> some View {
		Text(messageItem.text)
			.fixedSize(horizontal: false, vertical: true) // 允许垂直方向自由调整，但水平方向可以扩展
			.lineLimit(nil) // 确保文本可以显示多行
			.textSelection(.enabled)
			.padding(10)
			.background(messageItem.direction == .outgoing ? Appearance.Colors.bubbleGreen : Appearance.Colors.bubbleWhite)
			.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
			.applyTail(messageItem.direction)
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
