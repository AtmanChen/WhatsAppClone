import AppFeature
import ComposableArchitecture
import SwiftUI

@main
struct WhatsAppCloneApp: App {
	#if os(macOS)
	@NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
	#else
	@UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
	#endif
	var body: some Scene {
		WindowGroup {
			AppView(store: appDelegate.store)
//			#if os(macOS)
//				.frame(minWidth: 729, minHeight: 480)
//			#endif
		}
//		#if os(macOS)
//		.windowResizability(.contentMinSize)
//		#endif
	}
}
