import SwiftUI
import ComposableArchitecture
import Effect_Extensions
import Appearance

@Reducer
public struct UsernameReducer {
	public init() {}
	@ObservableState
	public struct State: Equatable, Identifiable {
		var item: ComponentsListenItem
		var showBio: Bool
		var name: String
		var bio: String?
		public init(item: ComponentsListenItem, showBio: Bool = false) {
			self.item = item
			self.showBio = showBio
			switch item {
			case .userItem(let userItem):
				self.name = userItem.username
				self.bio = userItem.bio
			case .channelItem(let channelItem):
				self.name = channelItem.name ?? "Group Chat"
			}
		}
		public var id: String {
			item.id
		}
	}
	public enum Action {
		case task
		case usernameUpdated(String)
		case userBioUpdated(String)
		case cancelLoad
		case delegate(Delegate)
		
		public enum Delegate {
			case titleUpdated(ComponentsListenItem)
		}
	}
	
	enum Cancel { case id }
	
	public var body: some ReducerOf<Self> {
		Reduce {
			state,
			action in
			switch action {
			case .cancelLoad:
				return .cancel(id: "channel_\(state.item.id)")
			case .delegate:
				return .none
			case .task:
				switch state.item {
				case let .userItem(userItem):
					var listener = Effect<UsernameReducer.Action>.listenToUsername(uid: userItem.id, mapToAction: { Action.usernameUpdated($0) })
					if state.showBio {
						listener = listener.merge(with: Effect.listenToUserBio(uid: userItem.id, mapToAction: { Action.userBioUpdated($0) }))
					}
					return listener.cancellable(id: Cancel.id, cancelInFlight: true)
				case let .channelItem(channelItem):
					return .listenToChannelInfo(channelId: channelItem.id, mapToAction: { Action.usernameUpdated($0.name ?? "Group Chat") } )
						.cancellable(id: "channel_\(channelItem.id)", cancelInFlight: true)
				}
				
			case let .usernameUpdated(updatedName):
				state.name = updatedName
				switch state.item {
				case let .userItem(userItem):
					var updatedUserItem = userItem
					updatedUserItem.username = updatedName
					return .send(.delegate(.titleUpdated(.userItem(updatedUserItem))))
				case let .channelItem(channelItem):
					var updatedChannelItem = channelItem
					updatedChannelItem.name = updatedName
					return .send(.delegate(.titleUpdated(.channelItem(updatedChannelItem))))
//					state.item = .channelItem(updatedChannelItem)
				}
				
			case let .userBioUpdated(bio):
				if case let .userItem(userItem) = state.item {
					var updatedUserItem = userItem
					updatedUserItem.bio = bio
//					state.item = .userItem(updatedUserItem)
					return .send(.delegate(.titleUpdated(.userItem(updatedUserItem))))
				}
				return .none
			}
		}
	}
}

public struct UsernameView: View {
	let store: StoreOf<UsernameReducer>
	public init(store: StoreOf<UsernameReducer>) {
		self.store = store
	}
	public var body: some View {
		VStack(alignment: .leading) {
			Text(store.name)
				.bold()
				.foregroundStyle(Appearance.Colors.whatsAppBlack)
			if store.showBio,
					let bio = store.bio,
				 !bio.isEmpty {
				Text(bio)
					.font(.caption)
					.foregroundStyle(.gray)
			}
		}
	}
}
