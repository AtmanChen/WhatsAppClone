import ChannelModels
import ComposableArchitecture
import SwiftUI
import UserModels

public enum ComponentsListenItem: Equatable, Identifiable, Hashable {
	case userItem(UserItem)
	case channelItem(ChannelItem)
	public var id: String {
		switch self {
		case .userItem(let userItem):
			return userItem.id
		case .channelItem(let channelItem):
			return channelItem.id
		}
	}
	public var profileImageUrl: String? {
		switch self {
		case .userItem(let userItem):
			return userItem.profileImage
		case .channelItem(let channelItem):
			return channelItem.thumbnailUrl
		}
	}
}

@Reducer
public struct StackAvatarUserNameBioReducer {
	public enum AvatarUserNameBioAlignment {
		case vertical, horizontal
	}
	public init() {}
	@ObservableState
	public struct State: Equatable, Identifiable {
		public var item: ComponentsListenItem
		var avatar: AvatarReducer.State
		var username: UsernameReducer.State
		var avatarUserNameBioAlignment: AvatarUserNameBioAlignment
		public init(
			item: ComponentsListenItem,
			avatarScale: AvatarScaleType,
			avatarUserNameBioAlignment: AvatarUserNameBioAlignment = .horizontal,
			showBio: Bool = false
		) {
			self.item = item
			self.avatarUserNameBioAlignment = avatarUserNameBioAlignment
			self.avatar = AvatarReducer.State(item: item, scaleType: avatarScale )
			self.username = UsernameReducer.State(item: item, showBio: showBio)
		}

		public var id: String {
			item.id
		}
		public var userItem: UserItem? {
			if case let .userItem(userItem) = item {
				return userItem
			}
			return nil
		}
	}

	public enum Action {
		case avatar(AvatarReducer.Action)
		case username(UsernameReducer.Action)
		case loadInfo
		case cancelLoad
		case delegate(Delegate)
		
		public enum Delegate {
			case itemUpdated(ComponentsListenItem)
		}
	}

	public var body: some ReducerOf<Self> {
		Scope(state: \.avatar, action: \.avatar) {
			AvatarReducer()
		}
		Scope(state: \.username, action: \.username) {
			UsernameReducer()
		}
		Reduce { state, action in
			switch action {
			case .loadInfo:
				return .run { send in
					await send(.avatar(.task))
					await send(.username(.task))
				}
			case let .avatar(.delegate(.profileImageUpdated(item))):
				return .send(.delegate(.itemUpdated(item)))
			case let .username(.delegate(.titleUpdated(item))):
				return .send(.delegate(.itemUpdated(item)))
			case .cancelLoad:
				return .run { send in
					await send(.avatar(.cancelLoad))
					await send(.username(.cancelLoad))
				}
			default: return .none
			}
		}
	}
}

public struct StackAvatarUserNameBioView<TrailingContent: View>: View {
	public enum TrailingContentPosition {
		case inline
		case topRight
		case custom(alignment: Alignment)
	}

	let store: StoreOf<StackAvatarUserNameBioReducer>
	private let trailingContent: TrailingContent
	private let trailingContentPosition: TrailingContentPosition
	public init(
		store: StoreOf<StackAvatarUserNameBioReducer>,
		trailingContentPosition: TrailingContentPosition = .inline,
		@ViewBuilder trailingContent: @escaping () -> TrailingContent = { EmptyView() }
	) {
		self.store = store
		self.trailingContentPosition = trailingContentPosition
		self.trailingContent = trailingContent()
	}

	public var body: some View {
		mainContent
			.overlay(overlayContent)
	}

	@ViewBuilder
	private var mainContent: some View {
		if store.avatarUserNameBioAlignment == .horizontal {
			HStack {
				AvatarView(store: store.scope(state: \.avatar, action: \.avatar))
				UsernameView(store: store.scope(state: \.username, action: \.username))
				if case .inline = trailingContentPosition {
					trailingContent
				}
			}
		} else {
			VStack {
				AvatarView(store: store.scope(state: \.avatar, action: \.avatar))
				UsernameView(store: store.scope(state: \.username, action: \.username))
				if case .inline = trailingContentPosition {
					trailingContent
				}
			}
		}
	}

	@ViewBuilder
	private var overlayContent: some View {
		switch trailingContentPosition {
		case .topRight:
			trailingContent
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
		case .custom(let alignment):
			trailingContent
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
		case .inline:
			EmptyView()
		}
	}
}
