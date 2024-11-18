import Dependencies
import DependenciesMacros
import FirebaseDatabase
import AuthModels
import Foundation

@DependencyClient
public struct DatabaseClient {
	public var usersRef: @Sendable () -> DatabaseReference = { .init() }
	public var channelsRef: @Sendable () -> DatabaseReference = { .init() }
	public var messagesRef: @Sendable () -> DatabaseReference = { .init() }
	public var userChannelsRef: @Sendable () -> DatabaseReference = { .init() }
	public var userDirectChannelsRef: @Sendable () -> DatabaseReference = { .init() }
}
