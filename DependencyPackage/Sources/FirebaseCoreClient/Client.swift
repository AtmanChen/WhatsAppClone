import Foundation
import DependenciesMacros
import Dependencies

@DependencyClient
public struct FirebaseCoreClient {
	public var config: @Sendable () -> Void
}
