import Appearance
import ChannelClient
import ChannelModels
import ComposableArchitecture
import Constant
import Effect_Extensions
import SwiftUI
import Toast
import UserModels
import UserUIComponents

public enum ChatPartnerPickerOption: String, CaseIterable, Identifiable {
	case newGroup = "New Group"
	case newContact = "New Contact"
	case newCommunity = "New Community"
	public var id: Self { self }
	public var title: String { rawValue }
	public var sfImageName: String {
		switch self {
		case .newGroup: return "person.2.fill"
		case .newContact: return "person.fill.badge.plus"
		case .newCommunity: return "person.3.fill"
		}
	}
}

@Reducer
public struct ChatPartnerPickerRedcuer {
	public init() {}
	@ObservableState
	public struct State: Equatable {
		var searchText = ""
		var options: [ChatPartnerPickerOption] = ChatPartnerPickerOption.allCases
		var fetchUsersCursor: String?
		var users: IdentifiedArrayOf<StackAvatarUserNameBioReducer.State> = []
		var isLoading = false
		var isPaginatable = true
		var toast: Toast?
		public init() {}
	}

	public enum Action: BindableAction {
		case binding(BindingAction<State>)
		case onTapCloseButton
		case onTapChatOption(ChatPartnerPickerOption)
		case onTapUser(UserItem)
		case task
		case fetchUsers
		case fetchUsersError(Error)
		case fetchUsersResponse(UserNode)
		case users(IdentifiedActionOf<StackAvatarUserNameBioReducer>)
		case delegate(Delegate)
		case cancelLoad

		public enum Delegate {
			case onTapCloseButton
			case onTapChatOption(ChatPartnerPickerOption)
			case jumpToChat(ChannelItem)
		}
	}

	@Dependency(\.dismiss) var dismiss
	@Dependency(\.channelClient.createChannel) var createChannel

	enum Cancel {
		case createChannel
	}

	public var body: some ReducerOf<Self> {
		BindingReducer()
		Reduce {
			state,
				action in
			switch action {
			case .binding:
				return .none
			case .cancelLoad:
				return .run { [users = state.users] send in
					await withTaskGroup(of: Void.self) { group in
						for user in users {
							group.addTask {
								await send(.users(.element(id: user.id, action: .cancelLoad)))
							}
						}
						await group.waitForAll()
					}
				}
			case .delegate:
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
				let addedUsers = userNode.users.map { StackAvatarUserNameBioReducer.State(item: .userItem($0), avatarScale: .small, avatarUserNameBioAlignment: .horizontal, showBio: true) }
				state.users.append(contentsOf: addedUsers)
				state.fetchUsersCursor = userNode.currentCursor
				state.isPaginatable = state.fetchUsersCursor != nil
				return .run { [addedUsers] send in
					for user in addedUsers {
						await send(.users(.element(id: user.id, action: .loadInfo)))
					}
				}
			case .onTapCloseButton:
				return .run { send in
					await send(.cancelLoad)
					await send(.delegate(.onTapCloseButton))
				}
			case let .onTapChatOption(option):
				return .send(.delegate(.onTapChatOption(option)))
			case let .onTapUser(userItem):
				return .run { [userItem] send in
					let channel = try await createChannel(nil, [userItem])
					await send(.delegate(.jumpToChat(channel)))
				} catch: { _, _ in

				}.cancellable(id: Cancel.createChannel, cancelInFlight: true)
			case .task:
//				return .run { send in
//					await send(.fetchUsers)
//				}
				return .none
			case let .users(.element(id: id, action: .delegate(.itemUpdated(updatedItem)))):
				state.users[id: id] = StackAvatarUserNameBioReducer.State(item: updatedItem, avatarScale: .medium, avatarUserNameBioAlignment: .horizontal, showBio: true)
				return .none
			default: return .none
			}
		}
		.forEach(\.users, action: \.users) {
			StackAvatarUserNameBioReducer()
		}
	}
}

public struct ChatPartnerPickerScreen: View {
	@Bindable var store: StoreOf<ChatPartnerPickerRedcuer>
	public init(store: StoreOf<ChatPartnerPickerRedcuer>) {
		self.store = store
	}

	public var body: some View {
		List {
			ForEach(store.options) { option in
				Button {
					store.send(.onTapChatOption(option))
				} label: {
					HStack {
						Image(systemName: option.sfImageName)
							.font(.footnote)
							.frame(width: 40, height: 40)
							.background(Color(.systemGray6))
							.clipShape(Circle())
						Text(option.title)
					}
				}
			}
			Section {
				ForEachStore(store.scope(state: \.users, action: \.users)) { userRowStore in
					StackAvatarUserNameBioView(store: userRowStore)
						.onTapGesture {
							store.send(.onTapUser(userRowStore.userItem!))
						}
				}
			} header: {
				Text("Contacts on WhatsApp")
					.textCase(nil)
					.bold()
			}
			if store.isPaginatable {
				loadMoreUsers()
			}
		}
		.searchable(text: $store.searchText,
		            placement: .navigationBarDrawer(displayMode: .always),
		            prompt: "Search name or number")
		.navigationTitle("New Chat")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button {
					store.send(.onTapCloseButton)
				} label: {
					Image(systemName: "xmark")
						.font(.footnote)
						.bold()
						.foregroundStyle(.gray)
						.padding(8)
						.background(Color(.systemGray5))
						.clipShape(Circle())
				}
			}
		}
		.task { await store.send(.task).finish() }
		.toast(toast: $store.toast)
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
		ChatPartnerPickerScreen(
			store: Store(
				initialState: ChatPartnerPickerRedcuer.State(),
				reducer: { ChatPartnerPickerRedcuer() }
			)
		)
	}
}
