import ComposableArchitecture
import Foundation
import SwiftUI
import Appearance
import NotificationCenterClient
import Constant
import Effect_Extensions
import FirebaseAuthClient

@Reducer
public struct SettingsTab {
	public init() {}
	@ObservableState
	public struct State: Equatable {
		var searchText = ""
		var userName = ""
		public init() {}
	}

	public enum Action: BindableAction {
		case binding(BindingAction<State>)
		case onTapSignOutButton
		case task
		case userInfo(String)
	}
	
	@Dependency(\.firebaseAuthClient.logOut) var logOut
	@Dependency(\.firebaseAuthClient.currentUser) var currentUser
	@Dependency(\.notificationCenter.post) var postNotification

	public var body: some ReducerOf<Self> {
		BindingReducer()
		Reduce {
			state,
			action in
			switch action {
			case .binding:
				return .none
			case .onTapSignOutButton:
				return .run { _ in
					try await logOut()
					postNotification(.signOut, nil, nil)
				}
			case .task:
				guard let currentUser = currentUser() else {
					return .none
				}
				return .listenToUserInfo(uid: currentUser.uid, mapToAction: { userItem in Action.userInfo(userItem?.username ?? "") })
			case let .userInfo(userName):
				state.userName = userName
				return .none
			}
		}
	}
}

public struct SettingsTabScreen: View {
	@Bindable var store: StoreOf<SettingsTab>
	public init(store: StoreOf<SettingsTab>) {
		self.store = store
	}

	public var body: some View {
		NavigationStack {
			List {
				Section {
					HStack {
						Circle()
							.frame(width: 55, height: 55)
						VStack(alignment: .leading, spacing: 0) {
							HStack {
								Text(store.userName)
									.font(.title2)
								Spacer()
								Appearance.Images.qrCode
									.renderingMode(.template)
									.padding(5)
									.foregroundStyle(.blue)
									.background(Color(.systemGray5))
									.clipShape(Circle())
							}
							Text("Hey there!I am using WhatsApp")
								.font(.callout)
								.foregroundStyle(.gray)
						}
					}
					.lineLimit(1)
					SettingsItemView(item: .avatar)
				}
				Section {
					SettingsItemView(item: .broadCastLists)
					SettingsItemView(item: .starredMessages)
					SettingsItemView(item: .linkedDevices)
				}
				Section {
					SettingsItemView(item: .account)
					SettingsItemView(item: .privacy)
					SettingsItemView(item: .chats)
					SettingsItemView(item: .notifications)
					SettingsItemView(item: .storage)
				}
				Section {
					SettingsItemView(item: .help)
					SettingsItemView(item: .tellFriend)
				}
			}
			.navigationTitle("Settings")
			.searchable(text: $store.searchText)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button("Sign Out") {
						store.send(.onTapSignOutButton)
					}
					.bold()
					.foregroundStyle(.red)
				}
			}
			.task {
				await store.send(.task).finish()
			}
		}
	}
}

struct SettingsItemView: View {
	let item: SettingsItem
	var body: some View {
		HStack {
			Group {
				if item.imageType == .systemImage {
					Image(systemName: item.imageName)
				} else {
					Image(item.imageName, bundle: Appearance.bundle)
						.renderingMode(.template)
				}
			}
			.foregroundStyle(.white)
			.frame(width: 30, height: 30)
			.background(item.backgroundColor)
			.clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
			.padding(.trailing, 8)
			Text(item.title)
				.font(.system(size: 18))
			Spacer()
		}
	}
}

#Preview {
	SettingsTabScreen(
		store: Store(
			initialState: SettingsTab.State(),
			reducer: { SettingsTab() }
		)
	)
}
