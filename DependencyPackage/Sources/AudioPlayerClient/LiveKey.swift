import AVFoundation
import Dependencies
import Foundation

extension AudioPlayerClient: DependencyKey {
	public static var liveValue: AudioPlayerClient = {
		let audioPlayer = AudioPlayer()
		return AudioPlayerClient(
			prepare: { url in
				try await audioPlayer.prepare(url)
			},
			play: { _ in
				audioPlayer.play()
			},
			pause: {
				audioPlayer.pause()
			},
			stop: {
				try audioPlayer.stop()
			},
			seekTo: { time in
				await audioPlayer.seekTo(time)
			},
			currentTime: { audioPlayer.currentTimeStream() },
			duration: { audioPlayer.duration },
			playbackStatus: { audioPlayer.playbackStatusStream() }
		)
	}()
}

private actor AudioPlayer {
	var player: AVPlayer?
	var timeObservation: Any?
	var statusObservation: Any?
	var itemObservation: NSObject?
	var duration: TimeInterval {
		player?.currentItem?.duration.seconds ?? 0
	}
	
	deinit {
		if let timeObservation {
			player?.removeTimeObserver(timeObservation)
		}
		if let statusObservation {
			NotificationCenter.default.removeObserver(statusObservation)
		}
		if itemObservation != nil {
			itemObservation = nil
		}
	}
	
	func prepare(_ url: URL) async throws {
		let asset = AVAsset(url: url)
		let playerItem = await AVPlayerItem(asset: asset)
		let duration = try await asset.load(.duration)
		guard duration.isValid, !duration.isIndefinite else {
			throw AudioPlayerError.invalidDuration
		}
		async let tracks = asset.load(.tracks)
		async let isPlayable = asset.load(.isPlayable)
		guard try await isPlayable, try !(await tracks).isEmpty else {
			throw AudioPlayerError.unplayableMedia
		}
		if player == nil {
			player = AVPlayer(playerItem: playerItem)
		} else {
			player?.replaceCurrentItem(with: playerItem)
		}
		
	}
	
	func play() {
		player?.play()
	}
	
	func pause() {
		player?.pause()
	}
	
	func stop() throws {
		player?.pause()
		player?.replaceCurrentItem(with: nil)
	}
	
	func seekTo(_ time: TimeInterval) async {
		let cmTime = CMTime(seconds: time, preferredTimescale: 1)
		await player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
	}
	
	func currentTimeStream() -> AsyncStream<TimeInterval> {
		AsyncStream { continuation in
			guard let player = player else {
				continuation.finish()
				return
			}
			let timeScale = CMTimeScale(NSEC_PER_SEC)
			let time = CMTime(seconds: 0.1, preferredTimescale: timeScale)
							
			self.timeObservation = player.addPeriodicTimeObserver(
				forInterval: time,
				queue: .main
			) { [weak player] time in
				guard player != nil else {
					continuation.finish()
					return
				}
				continuation.yield(time.seconds)
			}
							
			continuation.onTermination = { [weak self] _ in
				Task { [weak self] in
					await self?.removeTimeObserver()
				}
			}
		}
	}
	
	func playbackStatusStream() -> AsyncStream<PlaybackStatus> {
		AsyncStream { continuation in
			guard let player = player else {
				continuation.finish()
				return
			}
							
			// 监听播放状态
			self.statusObservation = NotificationCenter.default.addObserver(
				forName: .AVPlayerItemDidPlayToEndTime,
				object: player.currentItem,
				queue: .main
			) { _ in
				continuation.yield(.finished)
			}
			itemObservation = player.observe(\.timeControlStatus) { player, _ in
				switch player.timeControlStatus {
				case .playing:
					continuation.yield(.playing)
				case .paused:
					continuation.yield(.paused)
				case .waitingToPlayAtSpecifiedRate:
					break
				@unknown default:
					break
				}
			}
							
			continuation.onTermination = { [weak self] _ in
				Task { [weak self] in
					await self?.removeStatusObserver()
				}
			}
		}
	}
			
	private func removeTimeObserver() {
		if let timeObservation = timeObservation {
			player?.removeTimeObserver(timeObservation)
			self.timeObservation = nil
		}
	}
			
	private func removeStatusObserver() {
		if let statusObservation = statusObservation {
			NotificationCenter.default.removeObserver(statusObservation)
			self.statusObservation = nil
		}
	}
}

public enum PlaybackStatus: Equatable {
	case playing
	case paused
	case finished
	case error(String)
}

public enum AudioPlayerError: LocalizedError {
	case invalidDuration
	case unplayableMedia
	case unknown(Error)

	public var errorDescription: String? {
		switch self {
		case .invalidDuration:
			return "The audio file has an invalid duration"
		case .unplayableMedia:
			return "The audio file cannot be played"
		case .unknown(let error):
			return error.localizedDescription
		}
	}
}
