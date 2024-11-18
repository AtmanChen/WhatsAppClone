import AuthFeature
import ComposableArchitecture
import Constant
import Effect_Extensions

@Reducer
public struct AuthLogic {
	public func reduce(into state: inout AppReducer.State, action: AppReducer.Action) -> Effect<AppReducer.Action> {
		switch action {
		case .appDelegate(.delegate(.didFinishLaunching)):
			enum Cancel { case stateDidChange, signOut }
			return .merge(
				.listenToUserState(mapUserToAction: { user in
					Action.authUserResponse(user)
				})
				.cancellable(id: Cancel.stateDidChange),
				.listenToNotification(notificationNames: [.signOut], mapNotificationToAction: { _ in
					Action.didSignOut
				})
				.cancellable(id: Cancel.signOut)
			)
		case .didSignOut:
			state.authState = .loggedOut
			return .none
		case let .authUserResponse(user):
			state.authState = user == nil ? .loggedOut : .loggedIn
			return .none
		default: return .none
		}
	}
}
