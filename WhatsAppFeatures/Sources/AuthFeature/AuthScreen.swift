import SwiftUI
import ComposableArchitecture
import Appearance

@Reducer
public struct AuthReducer {
	
	@Reducer(state: .equatable)
	public enum Path {
		case signUpScreen(SignUpReducer)
	}
	
	public init() {}
	@ObservableState
	public struct State: Equatable {
		public init() {}
		var path = StackState<Path.State>()
		var login = LoginReducer.State()
	}
	public enum Action: BindableAction {
		case binding(BindingAction<State>)
		case login(LoginReducer.Action)
		case path(StackAction<Path.State, Path.Action>)
	}
	public var body: some ReducerOf<Self> {
		BindingReducer()
		Scope(state: \.login, action: \.login) {
			LoginReducer()
		}
		Reduce { state, action in
			switch action {
			case .binding:
				return .none
			case .login(.delegate(.onTapSignUpButton)):
				state.path.append(.signUpScreen(SignUpReducer.State()))
				return .none
			case .login:
				return .none
			case let .path(.element(id, action)):
				switch action {
				case .signUpScreen(.delegate(.onTapLoginButton)):
					state.path.pop(from: id)
					return .none
				default: return .none
				}
			case .path:
				return .none
			}
		}
		.forEach(\.path, action: \.path)
	}
}

public struct AuthScreen: View {
	let store: StoreOf<AuthReducer>
	public init(store: StoreOf<AuthReducer>) {
		self.store = store
	}
	public var body: some View {
		NavigationStackStore(store.scope(state: \.path, action: \.path)) {
			LoginScreen(store: store.scope(state: \.login, action: \.login))
		} destination: { store in
			switch store.case {
			case let .signUpScreen(signUpStore):
				SignUpScreen(store: signUpStore)
			}
		}

	}
}
