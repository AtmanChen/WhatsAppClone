import ChannelModels
import ComposableArchitecture
import SwiftUI
import UserModels

@Reducer
public struct ChatPartnerReducer {
	@Reducer(state: .equatable)
	public enum Path {
		case addGroupMembers(ChatPartnerAddGroupMembersReducer)
		case createGroupChat(ChatPartnerCreateGroupChatReducer)
	}
	
	public init() {}
	@ObservableState
	public struct State: Equatable {
		var path = StackState<Path.State>()
		var partnerPicker = ChatPartnerPickerRedcuer.State()
		public init() {}
	}

	public enum Action: BindableAction {
		case binding(BindingAction<State>)
		case partnerPicker(ChatPartnerPickerRedcuer.Action)
		case path(StackAction<Path.State, Path.Action>)
		case delegate(Delegate)
		case cancelLoad
		
		public enum Delegate {
			case jumpToChat(ChannelItem)
		}
	}
	
	@Dependency(\.dismiss) var dismiss
	
	public var body: some ReducerOf<Self> {
		BindingReducer()
		ChatPartnerPathReducer()
		Scope(state: \.partnerPicker, action: \.partnerPicker) {
			ChatPartnerPickerRedcuer()
		}
		Reduce { _, action in
			switch action {
			case .binding:
				return .none
			case .cancelLoad:
				return .run { send in
					await send(.partnerPicker(.cancelLoad))
				}
			case .delegate:
				return .none
			case .partnerPicker(.delegate(.onTapCloseButton)):
				return .run { send in
					await dismiss()
				}
			case let .partnerPicker(.delegate(.jumpToChat(channelItem))):
				return .run { send in
					await send(.partnerPicker(.cancelLoad))
					await send(.delegate(.jumpToChat(channelItem)))
				}
			case .partnerPicker:
				return .none
			case .path:
				return .none
			}
		}
		.forEach(\.path, action: \.path)
	}
}

public struct ChatPartnerScreen: View {
	@Bindable var store: StoreOf<ChatPartnerReducer>
	public init(store: StoreOf<ChatPartnerReducer>) {
		self.store = store
	}

	public var body: some View {
		NavigationStackStore(store.scope(state: \.path, action: \.path)) {
			ChatPartnerPickerScreen(store: store.scope(state: \.partnerPicker, action: \.partnerPicker))
		} destination: { store in
			switch store.case {
			case let .addGroupMembers(addGroupMemberStore):
				ChatPartnerAddGroupMembersScreen(store: addGroupMemberStore)
			case let .createGroupChat(createGroupChatStore):
				ChatPartnerCreateGroupChatScreen(store: createGroupChatStore)
			}
		}
	}
}

#Preview {
	ChatPartnerScreen(
		store: Store(
			initialState: ChatPartnerReducer.State(),
			reducer: { ChatPartnerReducer() }
		)
	)
}
