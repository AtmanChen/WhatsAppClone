import SwiftUI
import ComposableArchitecture
import Appearance
import AuthUIComponents
import FirebaseAuthClient
import Toast

@Reducer
public struct LoginReducer {
	public init() {}
	@ObservableState
	public struct State: Equatable {
		public init() {}
		var email: String = ""
		var password: String = ""
		var toast: Toast?
		var loginDisabled: Bool {
			email.isEmpty || password.isEmpty || isLoading
		}
		var isLoading = false
		var focus: Field?
		public enum Field: Hashable {
			case email
			case password
		}
	}
	public enum Action: BindableAction {
		case binding(BindingAction<State>)
		case onTapSignUpButton
		case onTapLogInButton
		case loginResponseFailed(String)
		case delegate(Delegate)
		
		public enum Delegate {
			case onTapSignUpButton
		}
	}
	
	@Dependency(\.firebaseAuthClient.login) var login
	
	public var body: some ReducerOf<Self> {
		BindingReducer()
		Reduce { state, action in
			switch action {
			case .binding:
				return .none
			case .onTapLogInButton:
				return .run { [email = state.email, password = state.password] _ in
					try await login(email, password)
				} catch: { error, send in
					await send(.loginResponseFailed(error.localizedDescription))
				}
			case .onTapSignUpButton:
				return .send(.delegate(.onTapSignUpButton))
			case let .loginResponseFailed(reason):
				state.toast = Toast(style: .string(reason, 2))
				return .none
			default: return .none
			}
		}
	}
}

public struct LoginScreen: View {
	@Bindable var store: StoreOf<LoginReducer>
	@FocusState var focus: LoginReducer.State.Field?
	public init(store: StoreOf<LoginReducer>) {
		self.store = store
	}
	public var body: some View {
		VStack {
			Spacer()
			AuthHeaderView()
			AuthTextField(
				icon: Image(systemName: "envelope"),
				placeholder: "Email",
				isSecure: false,
				keyboardType: .emailAddress,
				text: $store.email
			)
			.focused($focus, equals: .email)
			AuthTextField(
				icon: Image(systemName: "lock"),
				placeholder: "Password",
				isSecure: true,
				keyboardType: .default,
				text: $store.password
			)
			.focused($focus, equals: .password)
			forgotPasswordButton()
			AuthButton(
				title: "Log in now",
				icon: Image(systemName: "arrow.right"),
				isDisabled: store.loginDisabled
			) {
				store.send(.onTapLogInButton)
			}
			Spacer()
			signUpButton()
				.ignoresSafeArea(.keyboard)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color.teal.gradient)
		.bind($store.focus, to: $focus)
		.toast(toast: $store.toast)
	}
	
	private func forgotPasswordButton() -> some View {
		Button {
			
		} label: {
			Text("Forgot Password ?")
				.foregroundStyle(.white)
				.padding(.trailing, 32)
				.bold()
				.padding(.vertical)
				.frame(maxWidth: .infinity, alignment: .trailing)
		}
	}
	
	private func signUpButton() -> some View {
		Button {
			store.send(.onTapSignUpButton)
		} label: {
			HStack {
				Image(systemName: "sparkles")
				(
					Text("Don't have an account?")
					+
					Text(" Create one")
						.bold()
				)
				Image(systemName: "sparkles")
			}
			.foregroundStyle(.white)
			.frame(maxWidth: .infinity)
		}
	}
}

#Preview {
	LoginScreen(
		store: Store(
			initialState: LoginReducer.State(),
			reducer: { LoginReducer() }
		)
	)
}
