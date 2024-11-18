import Foundation
import Dependencies
import FirebaseCore

extension FirebaseCoreClient: DependencyKey {
	public static var liveValue = FirebaseCoreClient(
		config: { FirebaseApp.configure() }
	)
}
