import Appearance
import ChannelModels
import ComposableArchitecture
import Effect_Extensions
import Foundation
import Kingfisher
import SwiftUI
import UserModels

public enum AvatarScaleType: Equatable, Hashable {
	case mini, xSmall, small, medium, large, xLarge
	case custom(CGFloat)
	public var size: CGFloat {
		switch self {
		case .mini: return 30
		case .xSmall: return 40
		case .small: return 50
		case .medium: return 60
		case .large: return 80
		case .xLarge: return 120
		case .custom(let dimen): return dimen
		}
	}
}

@Reducer
public struct AvatarReducer {
	public init() {}
	@ObservableState
	public struct State: Equatable, Identifiable, Hashable {
		var item: ComponentsListenItem
		var scaleType: AvatarScaleType
		var profileImage: String? {
			item.profileImageUrl
		}
		public init(item: ComponentsListenItem, scaleType: AvatarScaleType = .medium) {
			self.item = item
			self.scaleType = scaleType
		}
		
		public init(uid: String, scaleType: AvatarScaleType = .medium) {
			self.item = .userItem(UserItem(uid: uid, username: "", email: "", bio: nil, profileImage: nil))
			self.scaleType = scaleType
		}

		public var id: String {
			item.id
		}
	}

	public enum Action {
		case task
		case profileImageUpdated(String)
		case cancelLoad
		case delegate(Delegate)
		
		public enum Delegate {
			case profileImageUpdated(ComponentsListenItem)
		}
	}

	enum Cancel { case id }

	public var body: some ReducerOf<Self> {
		Reduce {
			state,
				action in
			switch action {
			case .cancelLoad:
				return Effect.cancel(id: "channel_\(state.item.id)")
			case .task:
				switch state.item {
				case let .userItem(userItem):
					return .listenToUserProfileImage(uid: userItem.id, mapToAction: { Action.profileImageUpdated($0) })
						.cancellable(id: Cancel.id, cancelInFlight: true)
				case let .channelItem(channelItem):
					return .listenToChannelInfo(channelId: channelItem.id, mapToAction: { Action.profileImageUpdated($0.thumbnailUrl ?? "") })
						.cancellable(id: "channel_\(channelItem.id)", cancelInFlight: true)
				}
			case .delegate:
				return .none
			case let .profileImageUpdated(updatedProfileImage):
				switch state.item {
				case let .userItem(userItem):
					var updatedUserItem = userItem
					updatedUserItem.profileImage = updatedProfileImage
					return .send(.delegate(.profileImageUpdated(.userItem(updatedUserItem))))
				case let .channelItem(channelItem):
					var updatedChannelItem = channelItem
					updatedChannelItem.thumbnailUrl = updatedProfileImage
					return .send(.delegate(.profileImageUpdated(.channelItem(updatedChannelItem))))
//					state.item = .channelItem(updatedChannelItem)
					
				}
			}
		}
	}
}

public struct AvatarView: View {
	let store: StoreOf<AvatarReducer>
	public init(store: StoreOf<AvatarReducer>) {
		self.store = store
	}

	public var body: some View {
		Group {
			if let profileImage = store.profileImage {
				KFImage.url(URL(string: profileImage))
					.placeholder {
						placeholder()
					}
					.fade(duration: 0.25)
					.resizable()
					.scaledToFill()
					.clipShape(Circle())
			} else {
				placeholder()
			}
		}
		.frame(width: store.scaleType.size, height: store.scaleType.size)
	}
	
	private func placeholder() -> some View {
		switch store.item {
		case .channelItem:
			Image(systemName: "person.2.circle.fill")
				.resizable()
				.foregroundStyle(.gray)
		case .userItem:
			Image(systemName: "person.circle.fill")
				.resizable()
				.foregroundStyle(.gray)
		}
	}
}
