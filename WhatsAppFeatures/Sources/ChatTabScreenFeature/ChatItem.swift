import Appearance
import ChannelModels
import ComposableArchitecture
import Effect_Extensions
import Foundation
import SwiftUI
import UserUIComponents
import DateFormattClient

@Reducer
public struct ChatItem {
	public init() {}
	@ObservableState
	public struct State: Equatable, Identifiable, Comparable {
		public var channelItem: ChannelItem
		var avatar: AvatarReducer.State
		public init(channelItem: ChannelItem) {
			self.channelItem = channelItem
			let componentItem: ComponentsListenItem = channelItem.isGroupChat ? .channelItem(channelItem) : .userItem(channelItem.membersExcludingMe.first!)
			self.avatar = .init(item: componentItem, scaleType: .medium)
		}
		var lastMessageTimestampString: String {
			@Dependency(\.dateFormattClient.dayOrTimeRepresentation) var dayOrTimeRepresentation
			return dayOrTimeRepresentation(channelItem.lastMessageTimestamp)
		}

		public var id: String {
			channelItem.id
		}
		public static func < (lhs: ChatItem.State, rhs: ChatItem.State) -> Bool {
			return lhs.channelItem.lastMessageTimestamp < rhs.channelItem.lastMessageTimestamp
		}
		
	}

	public enum Action: BindableAction {
		case binding(BindingAction<State>)
		case avatar(AvatarReducer.Action)
		case task
		case channelItemUpdated(ChannelItem)
		case delegate(Delegate)

		public enum Delegate {
			case channelItemUpdated(ChannelItem)
		}
	}

	public var body: some ReducerOf<Self> {
		BindingReducer()
		Scope(state: \.avatar, action: \.avatar) {
			AvatarReducer()
		}
//		Scope(state: \.title, action: \.title) {
//			UsernameReducer()
//		}
		Reduce { state, action in
			switch action {
			case .binding:
				return .none
			case .avatar:
				return .none
			case .delegate:
				return .none
			case .task:
				return .listenToChannelInfo(channelId: state.channelItem.id, mapToAction: { Action.channelItemUpdated($0)})
			case let .channelItemUpdated(updatedChannelItem):
				return .send(.delegate(.channelItemUpdated(updatedChannelItem)))
//			case .title:
//				return .none
			}
		}
	}
}

public struct ChatItemView: View {
	let store: StoreOf<ChatItem>
	public init(store: StoreOf<ChatItem>) {
		self.store = store
	}

	public var body: some View {
		HStack(alignment: .center, spacing: 10) {
			AvatarView(store: store.scope(state: \.avatar, action: \.avatar))
			VStack(alignment: .leading, spacing: 3) {
				HStack {
					Text(store.channelItem.channelTitle)
						.lineLimit(1)
						.bold()
					Spacer()
					Text(store.lastMessageTimestampString)
						.foregroundStyle(.gray)
						.font(.system(size: 15))
				}
				HStack(spacing: 4) {
					if !store.channelItem.lastMessageType.iconName.isEmpty {
						Image(systemName: store.channelItem.lastMessageType.iconName)
							.imageScale(.small)
							.foregroundStyle(.gray)
					}
					Text(store.channelItem.previewMessage)
						.font(.system(size: 16))
						.lineLimit(2)
						.foregroundStyle(.gray)
				}
			}
			.task { await store.send(.task).finish() }
		}
	}
}

// #Preview {
//	ChatItemView(
//		store: Store(
//			initialState: ChatItem.State(channelItem: ChannelItem()),
//			reducer: { ChatItem() }
//		)
//	)
// }
