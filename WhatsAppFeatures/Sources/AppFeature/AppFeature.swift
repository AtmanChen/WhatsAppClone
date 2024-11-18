import SwiftUI
import Appearance
import ComposableArchitecture
import MainTabFeature
import AuthFeature
import LaunchFeature
import AuthModels
import TCAHelpers
import FirebaseAuthClient

@Reducer
public struct AppReducer {
	
	@Reducer(state: .equatable)
	public enum View {
		case launch(LaunchReducer)
		case auth(AuthReducer)
		case mainTab(MainTab)
	}
	
	public init() {}
	@ObservableState
	public struct State: Equatable {
		var appDelegate = AppDelegateReducer.State()
		var authState: AuthState = .launch
		var view: View.State
		public init() {
			view = .launch(LaunchReducer.State())
		}
	}
	public enum Action {
		case appDelegate(AppDelegateReducer.Action)
		case authUserResponse(FirebaseAuthClient.User?)
		case didSignOut
		case task
		case view(View.Action)
	}
	@Dependency(\.firebaseAuthClient) var firebaseAuthClient
	public var body: some ReducerOf<Self> {
		core
			.onChange(of: \.authState) { updateAuthState, state, _ in
				switch updateAuthState {
				case .launch:
					state.view = .launch(LaunchReducer.State())
					return .none
				case .loggedOut:
					state.view = .auth(AuthReducer.State())
					return .none
				case .loggedIn:
					state.view = .mainTab(MainTab.State())
					return .none
				}
			}
		Reduce { state, action in
			switch action {
			case .appDelegate:
				return .none
			case .task:
				return .run { send in
					try await firebaseAuthClient.autoLogin()
				} catch: { error, send in
					await send(.authUserResponse(nil))
				}
			case .view:
				return .none
			default: return .none
			}
		}
	}
	
	@ReducerBuilder<State, Action>
	private var core: some Reducer<State, Action> {
		Scope(state: \.appDelegate, action: \.appDelegate) {
			AppDelegateReducer()
		}
		Scope(state: \.view, action: \.view) {
			Scope(state: \.auth, action: \.auth) {
				AuthReducer()
			}
			Scope(state: \.mainTab, action: \.mainTab) {
				MainTab()
			}
		}
//		Scope(state: \.view.auth, action: \.view.auth) {
//			AuthReducer()
//		}
//		Scope(state: \.view.mainTab, action: \.view.mainTab) {
//			MainTab()
//		}
		AuthLogic()
//		RegisterTestAccount()
	}
}

public struct AppView: View {
	@Bindable var store: StoreOf<AppReducer>
	public init(store: StoreOf<AppReducer>) {
		self.store = store
	}
	public var body: some View {
		Group {
			switch store.scope(state: \.view, action: \.view).case {
			case let .launch(launchStore):
				LaunchScreen(store: launchStore)
			case let .auth(authStore):
				AuthScreen(store: authStore)
			case let .mainTab(mainTabStore):
				MainTabView(store: mainTabStore)
			}
		}
		.task { await store.send(.task).finish() }
	}
}

