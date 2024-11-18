import Appearance
import AuthModels
import ComposableArchitecture
import SwiftUI
import UserUIComponents
import Toast
import UserModels
import Constant

@Reducer
public struct ChatPartnerAddGroupMembersReducer {
	public init() {}
	@ObservableState
	public struct State: Equatable {
		public init() {}
		var searchText = ""
		var userItems: IdentifiedArrayOf<StackAvatarUserNameBioReducer.State> = []
		var fetchUsersCursor: String?
		var isLoading = false
		var isPaginatable = true
		public let membersLimit = 12
		@Shared(.inMemory("ChatPartnerSelectedGroupMembers")) var selectedUsers: IdentifiedArrayOf<StackAvatarUserNameBioReducer.State> = []
		var selectedUids: [String] {
			selectedUsers.map(\.id)
		}
		var toast: Toast?
		var isNextStepButtonDisabled: Bool {
			selectedUsers.isEmpty
		}
		var showSelectedUsers: Bool {
			!selectedUids.isEmpty
		}
	}

	public enum Action: BindableAction {
		case task
		case binding(BindingAction<State>)
		case delegate(Delegate)
		case onTapDeleteAvatar(UserItem)
		case onTapNextStepButton
		case onTapUserItem(UserItem)
		case insertSelectedUser(UserItem)
		case removeSelectedUser(UserItem)
		case selectedUsers(IdentifiedActionOf<StackAvatarUserNameBioReducer>)
		case userItems(IdentifiedActionOf<StackAvatarUserNameBioReducer>)
		case fetchUsers
		case fetchUsersError(Error)
		case fetchUsersResponse(UserNode)
		
		public enum Delegate {
			case onTapNextStepButton(Shared<IdentifiedArrayOf<StackAvatarUserNameBioReducer.State>>)
		}
		
	}

	public var body: some ReducerOf<Self> {
		BindingReducer()
		Reduce { state, action in
			switch action {
			case .binding:
				return .none
			case .task:
				state.selectedUsers.removeAll()
				return .none
			case .delegate:
				return .none
			case let .onTapDeleteAvatar(userItem):
				return .run { [userItem] send in
					await send(.removeSelectedUser(userItem), animation: .bouncy)
				}
			case .onTapNextStepButton:
				return .send(.delegate(.onTapNextStepButton(state.$selectedUsers)))
			case let .onTapUserItem(userItem):
				if state.selectedUsers[id: userItem.uid] != nil {
					return .run { [userItem] send in
						await send(.removeSelectedUser(userItem), animation: .bouncy)
					}
				} else {
					guard state.selectedUsers.count < state.membersLimit else {
						if state.toast == nil {
							state.toast = Toast(style: .string("Group members count limited to \(state.membersLimit)", 2))
						}
						return .none
					}
					return .run { [userItem] send in
						await send(.insertSelectedUser(userItem), animation: .bouncy)
					}
				}
			case let .userItems(.element(id: id, action: .delegate(.itemUpdated(updatedItem)))):
				state.userItems[id: id] = StackAvatarUserNameBioReducer.State(item: updatedItem, avatarScale: .medium, avatarUserNameBioAlignment: .horizontal, showBio: true)
				return .none
			case .userItems:
				return .none
			case let .selectedUsers(.element(id: id, action: .delegate(.itemUpdated(updatedItem)))):
				state.selectedUsers[id: id] = StackAvatarUserNameBioReducer.State(item: updatedItem, avatarScale: .medium, avatarUserNameBioAlignment: .vertical)
				return .none
			case .selectedUsers:
				return .none
			case let .insertSelectedUser(userItem):
				state.selectedUsers.insert(StackAvatarUserNameBioReducer.State(item: .userItem(userItem), avatarScale: .medium, avatarUserNameBioAlignment: .vertical), at: 0)
				return .run { [uid = userItem.uid] send in
					await send(.selectedUsers(.element(id: uid, action: .loadInfo)))
				}
			case let .removeSelectedUser(userItem):
				state.selectedUsers.remove(id: userItem.uid)
				return .none
				
			case .fetchUsers:
				guard !state.isLoading else {
					return .none
				}
				state.isLoading = true
				return Effect<Action>
					.fetchUsers(
						lastCursor: state.fetchUsersCursor,
						pageSize: Constant.Common.pageSize,
						mapToAction: {
							Action.fetchUsersResponse($0)
						},
						errorToAction: {
							Action.fetchUsersError($0)
						}
					)
			case let .fetchUsersError(error):
				state.isLoading = false
				if state.toast == nil {
					state.toast = Toast(style: .string(error.localizedDescription, 2))
				}
				return .none
			case let .fetchUsersResponse(userNode):
				state.isLoading = false
				let addedUsers = userNode.users.map { StackAvatarUserNameBioReducer.State(item: .userItem($0), avatarScale: .medium, avatarUserNameBioAlignment: .horizontal, showBio: true) }
				state.userItems.append(contentsOf: addedUsers)
				state.fetchUsersCursor = userNode.currentCursor
				state.isPaginatable = state.fetchUsersCursor != nil
				return .run { [addedUsers] send in
					for user in addedUsers {
						await send(.userItems(.element(id: user.id, action: .loadInfo)))
					}
				}
				
			}
		}
		.forEach(\.userItems, action: \.userItems) {
			StackAvatarUserNameBioReducer()
		}
		.forEach(\.selectedUsers, action: \.selectedUsers) {
			StackAvatarUserNameBioReducer()
		}
	}
}

public struct ChatPartnerAddGroupMembersScreen: View {
	@Bindable var store: StoreOf<ChatPartnerAddGroupMembersReducer>
	public init(store: StoreOf<ChatPartnerAddGroupMembersReducer>) {
		self.store = store
	}

	public var body: some View {
		List {
			if store.showSelectedUsers {
				ScrollView(.horizontal, showsIndicators: false) {
					HStack {
						ForEachStore(
							store.scope(
								state: \.selectedUsers,
								action: \.selectedUsers
							)
						) { userStore in
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
			}
			Section {
				ForEachStore(
					store.scope(
						state: \.userItems,
						action: \.userItems
					)
				) { userStore in
					StackAvatarUserNameBioView(store: userStore, trailingContentPosition: StackAvatarUserNameBioView.TrailingContentPosition.inline) {
						Spacer()
						Button {
							store.send(.onTapUserItem(userStore.userItem!), animation: .bouncy)
						} label: {
							let isSelected = store.selectedUids.contains(userStore.userItem!.uid)
							let imageName = isSelected ? "checkmark.circle.fill" : "circle"
							let foregroundColor = isSelected ? Appearance.Colors.whatsAppBlack : Color(.systemGray4)
							Image(systemName: imageName)
								.foregroundStyle(foregroundColor)
								.imageScale(.large)
								.animation(.default, value: isSelected)
						}
					}
				}
				if store.isPaginatable {
					loadMoreUsers()
				}
			}
		}
		.toolbar {
			ToolbarItem(placement: .principal) {
				VStack {
					Text("Add Participants")
						.bold()
					Text("\(store.selectedUids.count)/\(store.membersLimit)")
						.font(.footnote)
						.foregroundStyle(.gray)
				}
			}
			ToolbarItem(placement: .topBarTrailing) {
				Button {
					store.send(.onTapNextStepButton)
				} label: {
					Text("Next")
						.bold()
				}
				.disabled(store.isNextStepButtonDisabled)
			}
		}
		.searchable(
			text: $store.searchText,
			placement: .navigationBarDrawer(displayMode: .always),
			prompt: "Search name or number"
		)
		.toast(toast: $store.toast)
		.task { await store.send(.task).finish() }
	}
	
	private func loadMoreUsers() -> some View {
		ProgressView()
			.frame(maxWidth: .infinity)
			.listRowBackground(Color.clear)
			.task {
				await store.send(.fetchUsers)
			}
	}
}

#Preview {
	NavigationStack {
		ChatPartnerAddGroupMembersScreen(
			store: Store(
				initialState: ChatPartnerAddGroupMembersReducer.State(),
				reducer: { ChatPartnerAddGroupMembersReducer() }
			)
		)
	}
}
