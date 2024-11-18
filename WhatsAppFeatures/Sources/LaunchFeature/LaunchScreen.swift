import SwiftUI
import ComposableArchitecture
import Appearance
import AuthUIComponents
import Animations

@Reducer
public struct LaunchReducer {
	public init() {}
	@ObservableState
	public struct State: Equatable {
		public init() {}
	}
	public enum Action {}
	public func reduce(into state: inout State, action: Action) -> Effect<Action> {
		
	}
}

public struct LaunchScreen: View {
	let store: StoreOf<LaunchReducer>
	public init(store: StoreOf<LaunchReducer>) {
		self.store = store
	}
	public var body: some View {
		ZStack {
			LinearGradient(
				colors: [.teal, .teal.opacity(0.8), Appearance.Colors.bubbleGreen, Appearance.Colors.bubbleGreen.opacity(0.8)],
				startPoint: .top,
				endPoint: .bottom
			)
			AuthHeaderView()
				.breathingAnimation()
		}
		.ignoresSafeArea()
	}
}

#Preview {
	LaunchScreen(
		store: Store(
			initialState: LaunchReducer.State(),
			reducer: { LaunchReducer() }
		)
	)
}
