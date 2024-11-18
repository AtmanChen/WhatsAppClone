import AVFoundation
import ComposableArchitecture
import DateFormattClient
import Dependencies
import HapticsClient
import Speech
import UIKit

extension AudioRecorderClient: DependencyKey {
	public static var liveValue: Self {
		let audioRecorder = AudioRecorder()
		return Self(
			currentTime: { await audioRecorder.currentTime },
			requestRecordPermission: { await AudioRecorder.requestPermission() },
			startRecording: {
				let documentURL = URL.documentsDirectory
				@Dependency(\.dateFormattClient.stringWithFormat) var formatter
				let audioFileName = formatter("dd-MM-YY'-'HH:mm:ss") + ".m4a"
				let audioFileURL = documentURL.appendingPathComponent(audioFileName)
				generateHapticFeedback()
				return try await audioRecorder.start(url: audioFileURL)
			},
			stopRecording: {
				generateHapticFeedback()
				await audioRecorder.stop()
			},
			fileURL: {
				await audioRecorder.url
			},
			pauseRecording: {
				await audioRecorder.pause()
			},
			resumeRecording: {
				await audioRecorder.resume()
			},
			deleteAudioRecordingAt: { url in
				try FileManager.default.removeItem(at: url)
			},
			deleteAudioRecordings: {
				let documentURL = URL.documentsDirectory
				let audioRecordingsURLs = try FileManager.default.contentsOfDirectory(at: documentURL, includingPropertiesForKeys: nil)
				for audioRecordingURL in audioRecordingsURLs {
					try FileManager.default.removeItem(at: audioRecordingURL)
				}
			},
			stopRecordingAndDeleteAllFiles: {
				await audioRecorder.stop()
				let documentURL = URL.documentsDirectory
				let audioRecordingsURLs = try FileManager.default.contentsOfDirectory(at: documentURL, includingPropertiesForKeys: nil)
				for audioRecordingURL in audioRecordingsURLs {
					try FileManager.default.removeItem(at: audioRecordingURL)
				}
			}
		)
	}
}

private actor AudioRecorder {
	var delegate: Delegate?
	var recorder: AVAudioRecorder?

	var currentTime: TimeInterval? {
		guard
			let recorder = self.recorder,
			recorder.isRecording
		else { return nil }
		return recorder.currentTime
	}
	
	var url: URL? {
		self.recorder?.url
	}

	static func requestPermission() async -> Bool {
		await AVAudioApplication.requestRecordPermission()
	}
	
	func pause() {
		self.recorder?.pause()
	}
	
	func resume() {
		self.recorder?.record()
	}

	func stop() {
		self.recorder?.stop()
		try? AVAudioSession.sharedInstance().setActive(false)
	}

	func start(url: URL) async throws -> Bool {
		self.stop()

		let stream = AsyncThrowingStream<Bool, any Error> { continuation in
			do {
				self.delegate = Delegate(
					didFinishRecording: { flag in
						continuation.yield(flag)
						continuation.finish()
						try? AVAudioSession.sharedInstance().setActive(false)
					},
					encodeErrorDidOccur: { error in
						continuation.finish(throwing: error)
						try? AVAudioSession.sharedInstance().setActive(false)
					}
				)
				let recorder = try AVAudioRecorder(
					url: url,
					settings: [
						AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
						AVSampleRateKey: 44100,
						AVNumberOfChannelsKey: 1,
						AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
					])
				self.recorder = recorder
				recorder.delegate = self.delegate

				continuation.onTermination = { [recorder = UncheckedSendable(recorder)] _ in
					recorder.wrappedValue.stop()
				}

				try AVAudioSession.sharedInstance().setCategory(
					.playAndRecord, mode: .default, options: .defaultToSpeaker)
				try AVAudioSession.sharedInstance().setActive(true)
				self.recorder?.record()
			} catch {
				continuation.finish(throwing: error)
			}
		}

		for try await didFinish in stream {
			return didFinish
		}
		throw CancellationError()
	}
}

private final class Delegate: NSObject, AVAudioRecorderDelegate, Sendable {
	let didFinishRecording: @Sendable (Bool) -> Void
	let encodeErrorDidOccur: @Sendable ((any Error)?) -> Void

	init(
		didFinishRecording: @escaping @Sendable (Bool) -> Void,
		encodeErrorDidOccur: @escaping @Sendable ((any Error)?) -> Void
	) {
		self.didFinishRecording = didFinishRecording
		self.encodeErrorDidOccur = encodeErrorDidOccur
	}

	func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
		self.didFinishRecording(flag)
	}

	func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: (any Error)?) {
		self.encodeErrorDidOccur(error)
	}
}

func generateHapticFeedback() {
	let soundID: SystemSoundID = 1118
	AudioServicesPlaySystemSound(soundID)
	@Dependency(\.hapticsClient) var hapticsClient
	hapticsClient.impact(.medium)
}

//extension AudioPlayer: DependencyKey {
//	public static var liveValue: AudioPlayer {
//		let player = AVPlayer()
//		@Sendable func makeTimeStream() -> AsyncStream<TimeInterval> {
//			AsyncStream { continuation in
//				player.addPeriodicTimeObserver(
//					forInterval: CMTime(seconds: 0.1, preferredTimescale: 44100),
//					queue: .main
//				) { time in
//					let seconds = time.seconds
//					continuation.yield(seconds)
//				}
//			}
//		}
//
//		@Sendable func makePlaybackStatusStream() -> AsyncStream<PlaybackStatus> {
//			AsyncStream { continuation in
//
//				let observer = NotificationCenter.default.addObserver(
//					forName: .AVPlayerItemDidPlayToEndTime,
//					object: player.currentItem,
//					queue: .main
//				) { _ in
//					debugPrint("AVPlayerItemDidPlayToEndTime")
//					continuation.yield(.finished)
//					continuation.finish()
//				}
//				let timeControlStatusObserver = player.observe(\.timeControlStatus) { player, _ in
//					switch player.timeControlStatus {
//					case .playing:
//						continuation.yield(.playing)
//					case .paused:
//						continuation.yield(.paused)
//					case .waitingToPlayAtSpecifiedRate:
//						// 可以根据需要处理等待状态
//						break
//					@unknown default:
//						break
//					}
//				}
//
//				continuation.onTermination = { _ in
//					NotificationCenter.default.removeObserver(observer)
//					timeControlStatusObserver.invalidate()
//				}
//			}
//		}
//		return AudioPlayer(
//			prepare: { url in
//				let asset = AVAsset(url: url)
//				let playerItem = await AVPlayerItem(asset: asset)
//				let duration = try await asset.load(.duration)
//				guard duration.isValid, !duration.isIndefinite else {
//					throw AudioPlayerError.invalidDuration
//				}
//				async let tracks = asset.load(.tracks)
//				async let isPlayable = asset.load(.isPlayable)
//				guard try await isPlayable, try !(await tracks).isEmpty else {
//					throw AudioPlayerError.unplayableMedia
//				}
//				await MainActor.run {
//					player.replaceCurrentItem(with: playerItem)
//				}
//			},
//			play: { _ in
//				let session = AVAudioSession.sharedInstance()
//				try session.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
//				await MainActor.run {
//					player.play()
//				}
//				async let timeStream: Void = {
//					for await _ in makeTimeStream() {}
//				}()
//
//				async let statusStream: Void = {
//					for await _ in makePlaybackStatusStream() {}
//				}()
//
//				_ = await (timeStream, statusStream)
//			},
//			pause: {
//				await MainActor.run {
//					player.pause()
//				}
//			},
//			stop: {
//				await MainActor.run {
//					player.pause()
//					player.replaceCurrentItem(with: nil)
//				}
//			},
//			seekTo: { timeInterval in
//				await MainActor.run {
//					let cmTime = CMTime(seconds: timeInterval, preferredTimescale: 1)
//					player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
//				}
//			},
//			currentTime: makeTimeStream,
//			duration: {
//				player.currentItem?.duration.seconds ?? 0
//			},
//			playbackStatus: makePlaybackStatusStream
//		)
//	}
//}
//
//public enum PlaybackStatus: Equatable {
//	case playing
//	case paused
//	case finished
//	case error(String)
//}
//
//public enum AudioPlayerError: LocalizedError {
//	case invalidDuration
//	case unplayableMedia
//	case unknown(Error)
//
//	public var errorDescription: String? {
//		switch self {
//		case .invalidDuration:
//			return "The audio file has an invalid duration"
//		case .unplayableMedia:
//			return "The audio file cannot be played"
//		case .unknown(let error):
//			return error.localizedDescription
//		}
//	}
//}
