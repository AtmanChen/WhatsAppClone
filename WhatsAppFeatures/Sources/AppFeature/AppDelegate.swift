import ComposableArchitecture
import Foundation
import FirebaseCoreClient
import UIKit

#if os(macOS)
import Cocoa
public final class AppDelegate: NSObject, NSApplicationDelegate {
	public static let shared = AppDelegate()
	public let store = Store(
		initialState: AppReducer.State(),
		reducer: { AppReducer() }
	)
	public func applicationWillFinishLaunching(_ notification: Notification) {
		store.send(.appDelegate(.applicationWillFinishLaunching))
	}
}

#else

public final class AppDelegate: NSObject, UIApplicationDelegate {
	public static let shared = AppDelegate()
	public let store = Store(
		initialState: AppReducer.State(),
		reducer: { AppReducer() }
	)
	
	public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		store.send(.appDelegate(.didFinishLaunching(application, launchOptions)))
		return true
	}
}

#endif


@Reducer
public struct AppDelegateReducer {
	
	@ObservableState
	public struct State: Equatable {
		
	}
	
	public enum Action {
		#if os(macOS)
		case applicationWillFinishLaunching
		#else
		case didFinishLaunching(UIApplication, [UIApplication.LaunchOptionsKey: Any]?)
		case open(UIApplication, URL, [UIApplication.OpenURLOptionsKey: Any])
		case dynamicLink(URL?)
		case didReceiveRemoteNotification([AnyHashable: Any])
		case didRegisterForRemoteNotifications(TaskResult<Data>)
		case configurationForConnecting(UIApplicationShortcutItem?)
//		case userNotifications(UserNotificationClient.DelegateEvent)
//		case messaging(FirebaseMessagingClient.DelegateAction)
//		case createFirebaseRegistrationTokenResponse(TaskResult<God.CreateFirebaseRegistrationTokenMutation.Data>)
#endif
		case delegate(Delegate)

		public enum Delegate: Equatable {
			case didFinishLaunching
		}
	}
	
	@Dependency(\.firebaseCore) var firebaseCore
	
	public func reduce(into state: inout State, action: Action) -> Effect<Action> {
		switch action {
			#if os(macOS)
		case .applicationWillFinishLaunching:
			firebaseCore.configure()
			return .send(.delegate(.didFinishLaunching))
			#else
		case .didFinishLaunching(let uIApplication, let dictionary):
			firebaseCore.config()
			return .send(.delegate(.didFinishLaunching))
		case .open(let uIApplication, let uRL, let dictionary):
			return .none
		case .dynamicLink(let uRL):
			return .none
		case .didReceiveRemoteNotification(let dictionary):
			return .none
		case .didRegisterForRemoteNotifications(let taskResult):
			return .none
		case .configurationForConnecting(let uIApplicationShortcutItem):
			return .none
			#endif
		case .delegate:
			return .none
		}
	}
}
