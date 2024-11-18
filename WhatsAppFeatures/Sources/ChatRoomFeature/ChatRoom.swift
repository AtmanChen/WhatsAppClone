import Appearance
import AudioPlayerFeature
import ChannelClient
import ChannelModels
import Combine
import ComposableArchitecture
import Effect_Extensions
import FirebaseAuthClient
import FirebaseUsersClient
import Foundation
import MediaAttachment
import MediaAttachmentPreviewFeature
import MediaPlayerView
import MessageModels
import PhotosClient
import PhotosUI
import SwiftUI
import UI_Extensions
import UserModels
import UserUIComponents

public extension ChannelItem {
	var membersExcludingMe: [UserItem] {
		@Dependency(\.firebaseAuthClient.currentUser) var currentUser
		guard let currentUid = currentUser()?.uid else {
			return []
		}
		return members.filter { $0.uid != currentUid }
	}

	var channelTitle: String {
		if let name {
			return name
		}
		if !isGroupChat {
			return membersExcludingMe.first?.username ?? "Unknown"
		} else {
			if members.count == 3 {
				return members.first!.username + ", " + membersExcludingMe.map(\.username).joined(separator: " and ")
			} else {
				return members.first!.username + ", " + membersExcludingMe.suffix(2).map(\.username).joined(separator: " and ") + " and Others"
			}
		}
	}
}

public extension MediaAttachment {
	var messageType: MessageType {
		switch self {
		case .audio: return .audio
		case .image: return .photo
		case .video: return .video
		}
	}
}

private let historicalMessagesPageCount: UInt = 20

@Reducer
public struct ChatRoom {
	public init() {}
	@ObservableState
	public struct State: Equatable {
		public var channel: ChannelItem
		var directPartner: UserItem?
		var channelInfo: StackAvatarUserNameBioReducer.State
		var showPhotosPicker = false
		var playAttachment: MediaAttachment?
		var photoPickerItems: [PhotosPickerItem] = []
		var audioPlay: AudioPlayerReducer.State?
		var currentMessageCursor: String?
		var historicalMessagesRemains = false
		public init(channel: ChannelItem) {
			self.channel = channel
			let infoItem = channel.isGroupChat ? ComponentsListenItem.channelItem(channel) : ComponentsListenItem.userItem(channel.membersExcludingMe.first!)
			self.channelInfo = StackAvatarUserNameBioReducer.State(item: infoItem, avatarScale: .mini)
			self.messageList = MessageListReducer.State(channel: channel, messages: [])
		}

		var messageInputArea = ChatTextInputArea.State()
		var messageList: MessageListReducer.State
		var mediaAttachmentPreview: MediaAttachmentPreviewReducer.State?
	}

	public enum Action: BindableAction {
		case audioPlay(AudioPlayerReducer.Action)
		case binding(BindingAction<State>)
		case cancelTask(Cancel)
		case clearAttachments
		case task
		case mediaAttachmentPreview(MediaAttachmentPreviewReducer.Action)
		case messagesResponse(messages: [MessageItem], fromLatest: Bool)
		case messageInputArea(ChatTextInputArea.Action)
		case messageList(MessageListReducer.Action)
		case channelInfo(StackAvatarUserNameBioReducer.Action)
		case onTapNavigationBackButton
		case presentMediaAttachmentPreview([MediaAttachment])
		case stopPlayAttachment
		case loadHistorialMessages
		case presentAudioPlay(String, URL, TimeInterval)
		case dismissAudioPlay
		case updateMessageAttachmentsIsEmpty
		case sendMessage(String, [MediaAttachment])
	}

	public enum Cancel {
		case task
	}

	@Dependency(\.channelClient.sendTextMessageToChannel) var sendTextMessage
	@Dependency(\.channelClient.sendAttachmentsMessageToChannel) var sendAttachmentsMessageToChannel
	@Dependency(\.channelClient.listenToLatestMessageOfChannel) var listenToLatestMessageOfChannel
	@Dependency(\.channelClient.getHistoricalMessagesOfChannel) var getHistoricalMessagesOfChannel
	@Dependency(\.firebaseAuthClient.currentUser) var currentUser
	@Dependency(\.userInfoClient.getUser) var getUser
	@Dependency(\.dismiss) var dismiss

	public var body: some ReducerOf<Self> {
		BindingReducer()
		Scope(state: \.channelInfo, action: \.channelInfo) {
			StackAvatarUserNameBioReducer()
		}
		Scope(state: \.messageInputArea, action: \.messageInputArea) {
			ChatTextInputArea()
		}
		Scope(state: \.messageList, action: \.messageList) {
			MessageListReducer()
		}
		Reduce {
			state,
				action in
			switch action {
			case .messageList(.delegate(.loadMoreHistoricalMessages)):
				return .send(.loadHistorialMessages)
			case let .messageList(.delegate(.updateAudioPlaybackCurrentTime(_, currentTime))):
				return .send(.audioPlay(.seekTo(currentTime)))
			case let .messageList(.delegate(.toggleAudioPlayStatus(bubbleTag, audioFilePath, isPlaying, duration))):
				guard let audioFileURL = URL(string: audioFilePath) else {
					return .none
				}
				if state.audioPlay == nil {
					return .send(.presentAudioPlay(bubbleTag, audioFileURL, duration))
				} else {
					if state.audioPlay?.bubbleTag == bubbleTag {
						return isPlaying ? .send(.audioPlay(.play)) : .send(.audioPlay(.pause))
					} else {
						return .send(.audioPlay(.setURL(bubbleTag, audioFileURL, duration)))
					}
				}
			case let .audioPlay(.delegate(.playbackStatusChanged(bubbleTag, isPlaying))):
				return .send(.messageList(.toggleAudioPlayStatus(bubbleTag: bubbleTag, isPlaying: isPlaying)))
			case let .audioPlay(.delegate(.updateCurrentTime(bubbleTag, currentTime))):
				return .send(.messageList(.updateAudioPlaybackCurrentTime(bubbleTag: bubbleTag, updatedCurrentTime: currentTime)))
			case .audioPlay(.delegate(.didFinishPlaying)):
				var effect: Effect<Action> = .none
				if let bubbleTag = state.audioPlay?.bubbleTag {
					effect = effect.concatenate(with: .send(.messageList(.didFinishAudioPlayStatue(bubbleTag: bubbleTag))))
				}
				effect = effect.concatenate(with: .send(.dismissAudioPlay, animation: .easeInOut(duration: 0.25)))
				return effect
			case .audioPlay:
				return .none
			case .task:
				return .run { [channelId = state.channel.id] send in
					async let loadHistoricalMessages: Void = send(.loadHistorialMessages)
					async let sendChannelInfo: Void = send(.channelInfo(.loadInfo))
					async let subscribeMessages: Void = {
						for await updateMessage in listenToLatestMessageOfChannel(channelId) {
							await send(.messagesResponse(messages: [updateMessage], fromLatest: true))
						}
					}()
					_ = await (loadHistoricalMessages, sendChannelInfo, subscribeMessages)
				}.cancellable(id: Cancel.task, cancelInFlight: true)
			case let .cancelTask(cancelId):
				return Effect.cancel(id: cancelId)
			case .clearAttachments:
				if !state.photoPickerItems.isEmpty {
					state.photoPickerItems.removeAll()
				}
				if state.audioPlay != nil {
					return .send(.audioPlay(.stop))
				}
				if state.mediaAttachmentPreview == nil {
					return .none
				}
				return .send(.mediaAttachmentPreview(.clearAttachments))
			case .binding(\.photoPickerItems):
				let isMediaAttachmentPreviewPresented = state.mediaAttachmentPreview != nil
				let isPhotoPickerItemsEmpty = state.photoPickerItems.isEmpty
				return .run { [isMediaAttachmentPreviewPresented, isPhotoPickerItemsEmpty, selectedPhotoPickerItems = state.photoPickerItems] send in
					let selectedMedia = await selectedPhotoPickerItems.convertToMediaAttachment()
					if isMediaAttachmentPreviewPresented {
						await send(.mediaAttachmentPreview(.updateSelectedMedia(selectedMedia)))
					} else if !isPhotoPickerItemsEmpty {
						await send(.presentMediaAttachmentPreview(selectedMedia))
					}
					await send(.updateMessageAttachmentsIsEmpty)
				}
			case .binding:
				return .none
			case .channelInfo:
				return .none
			case .loadHistorialMessages:
				return .run { [channelId = state.channel.id, currentMessageCursor = state.currentMessageCursor] send in
					let messages = try await getHistoricalMessagesOfChannel(channelId, currentMessageCursor, historicalMessagesPageCount)
					await send(.messagesResponse(messages: messages, fromLatest: false))
				}
			case .messageInputArea(.delegate(.onTapMediaAttachmentButton)):
				state.showPhotosPicker = true
				return .none
			case let .messageInputArea(.delegate(.onTapSendButton(message))):
				let attachments = state.mediaAttachmentPreview?.selectedMedia ?? []
				return .send(.sendMessage(message, attachments.elements))
			case let .messageInputArea(.delegate(.didStopAudioRecording(attachment))):
				if state.mediaAttachmentPreview != nil {
					return .send(.mediaAttachmentPreview(.updateSelectedMedia([attachment])))
				} else {
					state.mediaAttachmentPreview = MediaAttachmentPreviewReducer.State(selectedMedia: [attachment])
				}
				return .send(.updateMessageAttachmentsIsEmpty)
			case .messageInputArea(.delegate(.confirmLeaving)):
				return .run { _ in
					await dismiss()
				}
			case .messageInputArea:
				return .none
			case let .sendMessage(message, attachments):
				return .run { [message, channelItem = state.channel] send in
					guard let currentUser = currentUser(),
					      let currentUserItem = try await getUser(currentUser.uid)
					else {
						return
					}
					if attachments.isEmpty {
						try await sendTextMessage(channelItem, currentUserItem, message)
					} else {
						await send(.clearAttachments)
						let messageParams = attachments.map { MessageUploadParams(
							channel: channelItem,
							text: message,
							type: $0.messageType,
							sender: currentUserItem,
							attachment: $0
						) }
						for messageParam in messageParams {
							try await sendAttachmentsMessageToChannel(messageParam)
						}
					}
				}
			case .messageList(.delegate(.onTapChatBackground)):
				return .send(.messageInputArea(.dismissKeyborad))
			case let .messageList(.delegate(.onTapAudioPlay(bubbleTag, audioFilePath, isPlaying, audioDuration))):
				guard let audioFileURL = URL(string: audioFilePath) else {
					return .none
				}
				if state.audioPlay == nil {
					return .send(.presentAudioPlay(bubbleTag, audioFileURL, audioDuration))
				} else {
					if let currentBubbleTag = state.audioPlay?.bubbleTag {
						if currentBubbleTag == bubbleTag {
							return isPlaying ? .send(.audioPlay(.play)) : .send(.audioPlay(.pause))
						} else {
							return .send(.audioPlay(.setURL(bubbleTag, audioFileURL, audioDuration)))
						}
					}
					return .none
				}
			case .messageList:
				return .none
			case let .messagesResponse(messages, fromLatest):
				if !fromLatest {
					state.historicalMessagesRemains = messages.count == historicalMessagesPageCount
					if let lastMessage = messages.last {
						state.currentMessageCursor = lastMessage.id
					}
				}
				return .send(.messageList(.messagesUpdated(messages: messages, fromLatest: fromLatest, historialMessagesRemains: state.historicalMessagesRemains)))
			case let .mediaAttachmentPreview(.delegate(.playAttachment(attachment))):
				if case let .audio(url, duration) = attachment {
					return .send(.presentAudioPlay("", url, duration), animation: .easeInOut(duration: 0.25))
				} else {
					state.playAttachment = attachment
				}
				return .none
			case let .mediaAttachmentPreview(.delegate(.didTapRemoveButton(attachment, isEmpty))):
				if isEmpty {
					state.mediaAttachmentPreview = nil
				}
				switch attachment {
				case .image,
				     .video:
					state.photoPickerItems.removeAll(where: { $0.id == attachment.id })
				default: break
				}
				return .send(.updateMessageAttachmentsIsEmpty)
			case .mediaAttachmentPreview(.delegate(.clearAttachmentsDone)):
				state.mediaAttachmentPreview = nil
				return .send(.updateMessageAttachmentsIsEmpty)
			case .mediaAttachmentPreview:
				return .none
			case .onTapNavigationBackButton:
				return .send(.messageInputArea(.onTapNavigationBackButton))
			case let .presentMediaAttachmentPreview(selectedMedia):
				state.mediaAttachmentPreview = MediaAttachmentPreviewReducer.State(selectedMedia: selectedMedia)
				return .none
			case .stopPlayAttachment:
				state.playAttachment = nil
				return .none

			case .updateMessageAttachmentsIsEmpty:
				let isMessageAttachmentsEmpty = state.mediaAttachmentPreview == nil
				return .send(.messageInputArea(.updateMessageAttachmentsIsEmpty(isMessageAttachmentsEmpty)))

			case let .presentAudioPlay(bubbleTag, url, duration):
				state.audioPlay = AudioPlayerReducer.State()
				return .send(.audioPlay(.setURL(bubbleTag, url, duration)))
			case .dismissAudioPlay:
				state.audioPlay = nil
				return .none
			}
		}
		.ifLet(\.mediaAttachmentPreview, action: \.mediaAttachmentPreview) {
			MediaAttachmentPreviewReducer()
		}
		.ifLet(\.audioPlay, action: \.audioPlay) {
			AudioPlayerReducer()
		}
	}
}

public struct ChatRoomScreen: View {
	@Bindable var store: StoreOf<ChatRoom>
	public init(store: StoreOf<ChatRoom>) {
		self.store = store
	}

	public var body: some View {
		MessageListView(
			store: store.scope(
				state: \.messageList,
				action: \.messageList
			)
		)
		.toolbar {
			leadingNavItems()
			trailingNavItems()
		}
		.animation(.snappy(duration: 0.25, extraBounce: 0), value: store.mediaAttachmentPreview != nil)
		.photosPicker(isPresented: $store.showPhotosPicker, selection: $store.photoPickerItems, maxSelectionCount: 6, photoLibrary: .shared())
		.fullScreenCover(item: $store.playAttachment) { videoAttachment in
			if let url = videoAttachment.playUrl {
				MediaPlayerView(player: AVPlayer(url: url)) {
					store.send(.stopPlayAttachment)
				}
			}
		}
		.safeAreaInset(edge: .top) {
			IfLetStore(store.scope(state: \.audioPlay, action: \.audioPlay)) { audioPlayStore in
				VStack {
					Divider()
					AudioPlayerView(store: audioPlayStore)
				}
			}
		}
		.safeAreaInset(edge: .bottom) {
			VStack(spacing: 0) {
				IfLetStore(
					store.scope(
						state: \.mediaAttachmentPreview,
						action: \.mediaAttachmentPreview
					)
				) { mediaAttachmentPreviewStore in
					MediaAttachmentPreview(store: mediaAttachmentPreviewStore)
						.transition(.move(edge: .bottom))
				}
				.animation(.snappy(duration: 0.25, extraBounce: 0), value: store.mediaAttachmentPreview != nil)
				ChatTextInputAreaView(
					store: store.scope(
						state: \.messageInputArea,
						action: \.messageInputArea
					)
				)
			}
		}
		.navigationBarBackButtonHidden()
		.navigationBarTitleDisplayMode(.inline)
		.task { await store.send(.task).finish() }
	}
}

extension ChatRoomScreen {
	@ToolbarContentBuilder
	private func leadingNavItems() -> some ToolbarContent {
		ToolbarItem(placement: .topBarLeading) {
			Button {
				store.send(.onTapNavigationBackButton)
			} label: {
				Image(systemName: "arrow.left")
					.renderingMode(.template)
					.fontWeight(.semibold)
					.foregroundStyle(Appearance.Colors.whatsAppBlack)
			}
		}
		ToolbarItem(placement: .topBarLeading) {
			StackAvatarUserNameBioView(store: store.scope(state: \.channelInfo, action: \.channelInfo))
		}
	}

	@ToolbarContentBuilder
	private func trailingNavItems() -> some ToolbarContent {
		ToolbarItemGroup(placement: .topBarTrailing) {
			Button {} label: {
				Image(systemName: "video")
			}

			Button {} label: {
				Image(systemName: "phone")
			}
		}
	}
}

#Preview {
	NavigationStack {
		ChatRoomScreen(
			store: Store(
				initialState: ChatRoom.State(channel: ChannelItem(from: [:])),
				reducer: { ChatRoom() }
			)
		)
	}
}
