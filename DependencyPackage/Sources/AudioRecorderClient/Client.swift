import AVFoundation
import DependenciesMacros
import Foundation

@DependencyClient
public struct AudioRecorderClient {
	public var currentTime: @Sendable () async -> TimeInterval?
	public var requestRecordPermission: @Sendable () async -> Bool = { false }
	public var startRecording: @Sendable () async throws -> Bool
	public var stopRecording: @Sendable () async -> Void
	public var fileURL: @Sendable () async -> URL?
	public var pauseRecording: @Sendable () async -> Void = {}
	public var resumeRecording: @Sendable () async -> Void = {}
	public var deleteAudioRecordingAt: @Sendable (URL) throws -> Void
	public var deleteAudioRecordings: @Sendable () throws -> Void
	public var stopRecordingAndDeleteAllFiles: @Sendable () async throws -> Void
}

//@DependencyClient
//public struct AudioPlayer {
//	public var prepare: @Sendable (URL) async throws -> Void
//	public var play: @Sendable (URL) async throws -> Void
//	public var pause: @Sendable () async throws -> Void
//	public var stop: @Sendable () async throws -> Void
//	public var seekTo: @Sendable (TimeInterval) async throws -> Void
//	public var currentTime: @Sendable () -> AsyncStream<TimeInterval> = { .never }
//	public var duration: @Sendable () -> TimeInterval = { 0 }
//	public var playbackStatus: @Sendable () -> AsyncStream<PlaybackStatus> = { .never }
//}
