import Foundation
import DependenciesMacros
import Dependencies

@DependencyClient
public struct AudioPlayerClient {
	public var prepare: @Sendable (URL) async throws -> Void
	public var play: @Sendable (URL) async throws -> Void
	public var pause: @Sendable () async throws -> Void
	public var stop: @Sendable () async throws -> Void
	public var seekTo: @Sendable (TimeInterval) async throws -> Void
	public var currentTime: @Sendable () async -> AsyncStream<TimeInterval> = { .never }
	public var duration: @Sendable () async -> TimeInterval = { 0 }
	public var playbackStatus: @Sendable () async -> AsyncStream<PlaybackStatus> = { .never }
}
