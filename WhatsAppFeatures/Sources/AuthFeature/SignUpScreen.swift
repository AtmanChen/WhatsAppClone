import SwiftUI
import Appearance
import AuthUIComponents
import ComposableArchitecture
import FirebaseAuthClient
import Toast

@Reducer
public struct SignUpReducer {
	public struct CreateAccountResponseCancelId: Hashable {}
	public init() {}
	@ObservableState
	public struct State: Equatable {
		public init() {}
		var email: String = ""
		var userName: String = ""
		var password: String = ""
		var isLoading = false
		var toast: Toast?
		var signUpDisabled: Bool {
			email.isEmpty || userName.isEmpty || password.isEmpty || isLoading
		}
		var focus: Field?
		public enum Field: Hashable {
			case email
			case password
			case repeatPassword
		}
	}
	public enum Action: BindableAction {
		case binding(BindingAction<State>)
		case createAccountResponse(Result<Void, Error>)
		case onTapCreateAccountButton
		case onTapLoginButton
		case delegate(Delegate)
		
		public enum Delegate {
			case onTapLoginButton
		}
	}
	
	@Dependency(\.firebaseAuthClient) var firebaseAuthClient
	
	public var body: some ReducerOf<Self> {
		BindingReducer()
		Reduce { state, action in
			switch action {
			case .binding:
				return .none
			case let .createAccountResponse(result):
				state.isLoading = false
				if case let .failure(error) = result {
					state.toast = Toast(style: .string(error.localizedDescription, 2))
				}
				return .none
			case .onTapCreateAccountButton:
				state.isLoading = true
				return .run { [email = state.email, username = state.userName, password = state.password] send in
					try await firebaseAuthClient.createAccount(email, username, password)
				} catch: { error, send in
					await send(.createAccountResponse(.failure(error)))
				}
					
			case .onTapLoginButton:
				return .send(.delegate(.onTapLoginButton))
			default: return .none
			}
		}
	}
}

public struct SignUpScreen: View {
	@Bindable var store: StoreOf<SignUpReducer>
	@FocusState var focus: SignUpReducer.State.Field?
	public init(store: StoreOf<SignUpReducer>) {
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
			AuthTextField(
				icon: Image(systemName: "at"),
				placeholder: "Username",
				isSecure: false,
				keyboardType: .default,
				text: $store.userName
			)
			AuthTextField(
				icon: Image(systemName: "lock"),
				placeholder: "Password",
				isSecure: true,
				keyboardType: .default,
				text: $store.password
			)
			AuthButton(
				title: "Create an Account",
				icon: Image(systemName: "arrow.right"),
				isDisabled: store.signUpDisabled
			) {
				store.send(.onTapCreateAccountButton)
			}
			.padding(.top, 36)
			Spacer()
			loginButton()
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(
			LinearGradient(colors: [.green, .green.opacity(0.8), .teal], startPoint: .top, endPoint: .bottom)
		)
		.navigationBarBackButtonHidden()
		.bind($store.focus, to: $focus)
		.toast(toast: $store.toast)
	}
	
	private func loginButton() -> some View {
		Button {
			store.send(.onTapLoginButton)
		} label: {
			HStack {
				Image(systemName: "sparkles")
				(
					Text("Already have an account?")
					+
					Text(" Login")
						.bold()
				)
				Image(systemName: "sparkles")
			}
			.foregroundStyle(.white)
			.frame(maxWidth: .infinity)
		}
		
	}
}
