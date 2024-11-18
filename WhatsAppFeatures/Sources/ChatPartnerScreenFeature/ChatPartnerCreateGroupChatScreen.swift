import SwiftUI
import ComposableArchitecture
import UserUIComponents
import UserModels
import Appearance
import ChannelClient
import ChannelModels
import Toast

@Reducer
public struct ChatPartnerCreateGroupChatReducer {
	public init() {}
	@ObservableState
	public struct State: Equatable {
		var groupName: String = ""
		var createChatButtonDisabled: Bool {
			selectedUsers.isEmpty
		}
		var toast: Toast?
		@Shared var selectedUsers: IdentifiedArrayOf<StackAvatarUserNameBioReducer.State>
		public init(selectedUsers: Shared<IdentifiedArrayOf<StackAvatarUserNameBioReducer.State>>) {
			self._selectedUsers = selectedUsers
		}
	}
	public enum Action: BindableAction {
		case binding(BindingAction<State>)
		case selectedUsers(IdentifiedActionOf<StackAvatarUserNameBioReducer>)
		case onTapDeleteAvatar(UserItem)
		case onTapCreatChatButton
		case failedToCreateChannel(String)
		case delegate(Delegate)
		
		public enum Delegate {
			case createChannelResponse(ChannelItem)
		}
	}
	
	@Dependency(\.channelClient.createChannel) var createChannel
	
	public var body: some ReducerOf<Self> {
		BindingReducer()
		Reduce { state, action in
			switch action {
			case .binding:
				return .none
			case .delegate:
				return .none
			case let .failedToCreateChannel(reason):
				if state.toast == nil {
					state.toast = Toast(style: .string(reason, 2))
				}
				return .none
			case let .selectedUsers(.element(id: id, action: .delegate(.itemUpdated(updatedItem)))):
				state.selectedUsers[id: id] = StackAvatarUserNameBioReducer.State(item: updatedItem, avatarScale: .medium, avatarUserNameBioAlignment: .vertical)
				return .none
			case .selectedUsers:
				return .none
			case .onTapCreatChatButton:
				return .run { [groupName = state.groupName, partners = state.selectedUsers.compactMap { $0.userItem }] send in
					let channel = try await createChannel(groupName, partners)
					await send(.delegate(.createChannelResponse(channel)))
				} catch: { error, send in
					await send(.failedToCreateChannel(error.localizedDescription))
				}
			case let .onTapDeleteAvatar(userItem):
				state.selectedUsers.remove(id: userItem.uid)
				return .none
			}
		}
		.forEach(\.selectedUsers, action: \.selectedUsers) {
			StackAvatarUserNameBioReducer()
		}
	}
}

public struct ChatPartnerCreateGroupChatScreen: View {
	@Bindable var store: StoreOf<ChatPartnerCreateGroupChatReducer>
	public init(store: StoreOf<ChatPartnerCreateGroupChatReducer>) {
		self.store = store
	}
	public var body: some View {
		List {
			Section {
				chatCreateHeaderView()
			}
			Section {
				Text("Disappearing Messages")
				Text("Group Permissions")
			}
			Section {
				ScrollView {
					HStack {
						ForEachStore(store.scope(state: \.selectedUsers, action: \.selectedUsers)) { userStore in
							StackAvatarUserNameBioView(store: userStore, trailingContentPosition: StackAvatarUserNameBioView.TrailingContentPosition.topRight) {
								Button {
									store.send(.onTapDeleteAvatar(userStore.state.userItem!), animation: .bouncy)
								} label: {
									Image(systemName: "xmark")
										.imageScale(.small)
										.fontWeight(.semibold)
										.foregroundStyle(Color(.systemGray4))
										.padding(4)
										.background(Appearance.Colors.whatsAppBlack)
										.clipShape(Circle())
								}
							}
						}
					}
				}
			} header: {
				Text("Participants: \(store.selectedUsers.count)/12")
			}
			.listRowBackground(Color.clear)
		}
		.navigationTitle("New Group")
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button("Create") {
					store.send(.onTapCreatChatButton)
				}
				.bold()
				.disabled(store.createChatButtonDisabled)
			}
		}
		.toast(toast: $store.toast)
	}
	
	private func chatCreateHeaderView() -> some View {
		HStack {
			Button {
				
			} label: {
				ZStack {
					Image(systemName: "camera.fill")
						.imageScale(.large)
				}
				.frame(width: 60, height: 60)
				.background(Color(.systemGray6))
				.clipShape(Circle())
			}
			TextField(
				"",
				text: $store.groupName,
				prompt: Text("Group Name (optional)"),
				axis: .vertical
			)
		}
	}
}

#Preview {
	NavigationStack {
		ChatPartnerCreateGroupChatScreen(
			store: Store(
				initialState: ChatPartnerCreateGroupChatReducer.State(
					selectedUsers: .init(
						.init(
							uniqueElements: [StackAvatarUserNameBioReducer.State(
								item: .userItem(
									UserItem(
										uid: "001",
										username: "Lambert",
										email: "lambert@example",
										bio: "This is bio",
										profileImage: nil
									)
								),
								avatarScale: .medium,
								avatarUserNameBioAlignment: .vertical
							)]
						)
					)
				),
				reducer: {
					ChatPartnerCreateGroupChatReducer()
				}
			)
		)
	}
}
