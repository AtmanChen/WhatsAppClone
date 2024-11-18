import Appearance
import ChannelModels
import ChatPartnerScreenFeature
import ChatRoomFeature
import ComposableArchitecture
import Effect_Extensions
import Foundation
import SwiftUI
import UserModels

@Reducer
public struct ChatTab {
	@Reducer(state: .equatable)
	public enum Destination {
		case chatRoom(ChatRoom)
		case chatPartner(ChatPartnerReducer)
	}
	
	public init() {}
	@ObservableState
	public struct State: Equatable {
		var searchText = ""
		var chatItems: IdentifiedArrayOf<ChatItem.State> = []
		@Presents var destination: Destination.State?
		public init() {}
	}
	
	public enum Action: BindableAction {
		case task
		case binding(BindingAction<State>)
		case chatItems(IdentifiedActionOf<ChatItem>)
		case destination(PresentationAction<Destination.Action>)
		case onTapChatItem(ChannelItem)
		case onTapNewChat
		case channelsResponse([ChannelItem])
	}
	
	public var body: some ReducerOf<Self> {
		BindingReducer()
		Reduce { state, action in
			switch action {
			case let .channelsResponse(channelItems):
				for channelItem in channelItems {
					let chatItem = ChatItem.State(channelItem: channelItem)
							
					if let existingIndex = state.chatItems.index(id: chatItem.id) {
						// 如果项目已存在，先移除它
						state.chatItems.remove(at: existingIndex)
					}
							
					// 找到正确的插入位置
					let insertionIndex = state.chatItems.firstIndex { $0 < chatItem } ?? state.chatItems.endIndex
							
					// 插入到正确的位置
					state.chatItems.insert(chatItem, at: insertionIndex)
				}
				return .none
			case .task:
				return Effect.listenToCurrentUserChannels(mapToAction: { Action.channelsResponse($0) })
			case .binding:
				return .none
			case let .chatItems(.element(id: _, action: .delegate(.channelItemUpdated(updatedChannelItem)))):
				return .send(.channelsResponse([updatedChannelItem]), animation: .snappy)
			case .chatItems:
				return .none
			case let .destination(.presented(.chatPartner(.delegate(.jumpToChat(channelItem))))):
				return .run { [channelItem] send in
					await send(.onTapChatItem(channelItem))
				}
			case .destination:
				return .none
			case let .onTapChatItem(channelItem):
				state.destination = .chatRoom(ChatRoom.State(channel: channelItem))
				return .none
			case .onTapNewChat:
				state.destination = .chatPartner(ChatPartnerReducer.State())
				return .none
			}
		}
		.forEach(\.chatItems, action: \.chatItems) {
			ChatItem()
		}
		.ifLet(\.$destination, action: \.destination) {
			Destination.body
		}
	}
}

public struct ChatTabScreen: View {
	@Bindable var store: StoreOf<ChatTab>
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	public init(store: StoreOf<ChatTab>) {
		self.store = store
	}

	public var body: some View {
		Group {
			if horizontalSizeClass == .regular {
				NavigationSplitView {
					chatItemsListView
				} detail: {
					IfLetStore(store.scope(state: \.destination?.chatRoom, action: \.destination.chatRoom)) { chatRoomStore in
						ChatRoomScreen(store: chatRoomStore)
							.id(chatRoomStore.channel.id)
					}
				}

			} else {
				NavigationStack {
					chatItemsListView
						.navigationDestination(item: $store.scope(state: \.destination?.chatRoom, action: \.destination.chatRoom)) { chatRoomStore in
							ChatRoomScreen(store: chatRoomStore)
						}
				}
			}
		}
		.sheet(item: $store.scope(state: \.destination?.chatPartner, action: \.destination.chatPartner)) { chatPartnerStore in
			ChatPartnerScreen(store: chatPartnerStore)
		}
		.task { await store.send(.task).finish() }
	}
	
	private var chatItemsListView: some View {
		List {
			archivedButton()
			ForEachStore(store.scope(state: \.chatItems, action: \.chatItems)) { chatItemStore in
				Button {
					store.send(.onTapChatItem(chatItemStore.channelItem))
				} label: {
					ChatItemView(store: chatItemStore)
				}
			}
			inboxFooterView()
				.listRowSeparator(.hidden)
		}
		.listStyle(.plain)
		.navigationTitle("Chats")
		.searchable(text: $store.searchText)
		.toolbar {
			leadingNavItem()
			trailingNavItems()
		}
	}
}

extension ChatTabScreen {
	@ToolbarContentBuilder
	private func leadingNavItem() -> some ToolbarContent {
		ToolbarItem(placement: .topBarLeading) {
			Menu {
				Button {} label: {
					Label("Select Chats", systemImage: "checkmark.circle")
				}
			} label: {
				Image(systemName: "ellipsis.circle")
			}
		}
	}
	
	@ToolbarContentBuilder
	private func trailingNavItems() -> some ToolbarContent {
		ToolbarItemGroup(placement: .topBarTrailing) {
			Button {} label: {
				Appearance.Images.circle
			}
			
			Button {} label: {
				Image(systemName: "camera")
			}
			
			Button {
				store.send(.onTapNewChat)
			} label: {
				Appearance.Images.plus
			}
		}
	}
	
	private func archivedButton() -> some View {
		Button {} label: {
			Label("Archived", systemImage: "archivebox.fill")
				.bold()
				.padding()
				.foregroundStyle(.gray)
		}
	}
	
	private func inboxFooterView() -> some View {
		HStack {
			Image(systemName: "lock.fill")

			Text("Your personal messages are ")
				+
				Text("end-to-end encrypted")
				.foregroundStyle(.blue)
		}
		.foregroundStyle(.gray)
		.font(.caption)
		.padding(.horizontal)
	}
}

#Preview {
	ChatTabScreen(
		store: Store(
			initialState: ChatTab.State(),
			reducer: { ChatTab() }
		)
	)
}
