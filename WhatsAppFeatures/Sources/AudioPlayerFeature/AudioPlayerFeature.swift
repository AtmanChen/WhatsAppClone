import Appearance
import AudioPlayerClient
import ComposableArchitecture
import Foundation
import SwiftUI

@Reducer
public struct AudioPlayerReducer {
	public init() {}
	@ObservableState
	public struct State: Equatable {
		public var isPlaying: Bool = false
		public var currentTime: TimeInterval = 0
		public var duration: TimeInterval = 0
		public var url: URL?
		public var playbackStatus: PlaybackStatus = .paused
		public var bubbleTag: String = ""
		public enum LoadingState: Equatable {
			case idle
			case loading
			case ready
			case failed(String)
		}

		public var loadingState: LoadingState = .loading

		var canPlay: Bool {
			loadingState == .ready && url != nil
		}

		var playProgress: Double {
			currentTime / duration
		}

		public init() {}
	}

	public enum Action {
		case play
		case pause
		case stop
		case seekTo(TimeInterval)
		case setURL(String, URL, TimeInterval)
		case togglePlayStatus
		case onTapCloseButton

		// 加载相关
		case loadAudio
		case loadingComplete
		case loadingFailed(String)

		// 播放相关
		case updateCurrentTime(TimeInterval)
		case playbackFinished
		case playbackStatusChanged(PlaybackStatus)

		case delegate(Delegate)

		public enum Delegate {
			case playbackStatusChanged(bubbleTag: String, isPlaying: Bool)
			case didFinishPlaying
			case updateCurrentTime(bubbleTag: String, currentTime: TimeInterval)
		}
	}
	
	public enum Cancel {
		case ID
	}

	@Dependency(\.audioPlayerClient) var audioPlayer

	public func reduce(into state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case .delegate:
			return .none
		case .onTapCloseButton:
			return .run { send in
				try await audioPlayer.stop()
				await send(.delegate(.didFinishPlaying), animation: .bouncy)
			}
		case .stop:
			return .send(.onTapCloseButton)
		case .play:
			guard state.canPlay else { return .none }
			state.isPlaying = true
			return .run { [url = state.url!] send in
				async let statusStream: Void = {
					for await playbackStatus in await audioPlayer.playbackStatus() {
						await send(.playbackStatusChanged(playbackStatus))
					}
				}()

				async let timeStream: Void = {
					for await time in await audioPlayer.currentTime() {
						await send(.updateCurrentTime(time))
					}
				}()

				// 然后开始播放
				try await audioPlayer.play(url)

				// 等待流完成
				_ = await (statusStream, timeStream)
			}.cancellable(id: Cancel.ID)
		case .pause:
			guard state.isPlaying else { return .none }
			state.isPlaying = false
			return .run { _ in
				try await audioPlayer.pause()
			}
		case let .seekTo(timeInterval):
			guard state.canPlay else { return .none }
			return .run { send in
				try await audioPlayer.seekTo(timeInterval)
				await send(.updateCurrentTime(timeInterval))
			}
		case let .setURL(bubbleTag, url, duration):
			let previousBubbleTag = state.bubbleTag
			guard state.url != url else {
				return .none
			}
			state.bubbleTag = bubbleTag
			state.url = url
			state.duration = duration
			state.currentTime = 0
			state.loadingState = .loading
			state.isPlaying = false
			return .concatenate(
				.cancel(id: Cancel.ID),
				.send(.delegate(.updateCurrentTime(bubbleTag: previousBubbleTag, currentTime: 0))),
				.run { _ in try await audioPlayer.stop() },
				.send(.loadAudio)
			)

		case .loadAudio:
			guard let url = state.url else { return .none }
			state.loadingState = .loading
			return .run { send in
				try await audioPlayer.prepare(url)
				await send(.loadingComplete)
				await send(.play)
			} catch: { error, send in
				await send(.loadingFailed(error.localizedDescription))
			}
		case .loadingComplete:
			state.loadingState = .ready
			return .none
		case let .loadingFailed(errorMessage):
			state.loadingState = .failed(errorMessage)
			state.isPlaying = false
			return .send(.delegate(.didFinishPlaying), animation: .easeInOut(duration: 0.25))
		case let .updateCurrentTime(timeInteral):
			if state.isPlaying {
				state.currentTime = timeInteral
			}
			return .send(.delegate(.updateCurrentTime(bubbleTag: state.bubbleTag, currentTime: timeInteral)))
		case .playbackFinished:
			state.isPlaying = false
			state.currentTime = 0
			return .none

		case let .playbackStatusChanged(status):
			state.playbackStatus = status
			switch state.playbackStatus {
			case .finished:
				return .send(.delegate(.didFinishPlaying), animation: .easeInOut(duration: 0.25))
			case .error:
				state.isPlaying = false
				return .send(.delegate(.playbackStatusChanged(bubbleTag: state.bubbleTag, isPlaying: false)))
			case .playing:
				return .send(.delegate(.playbackStatusChanged(bubbleTag: state.bubbleTag, isPlaying: true)))
			case .paused:
				return .send(.delegate(.playbackStatusChanged(bubbleTag: state.bubbleTag, isPlaying: false)))
			}
		case .togglePlayStatus:
			if state.isPlaying {
				return .send(.pause)
			} else {
				return .send(.play)
			}
		}
	}
}

public struct AudioPlayerView: View {
	@Bindable var store: StoreOf<AudioPlayerReducer>
	public init(store: StoreOf<AudioPlayerReducer>) {
		self.store = store
	}

	public var body: some View {
		ZStack(alignment: .bottom) {
			HStack {
				Group {
					if store.loadingState == .loading {
						ProgressView()
					} else {
						Button {
							store.send(.togglePlayStatus)
						} label: {
							Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
								.renderingMode(.template)
								.fontWeight(.bold)
						}
					}
				}
				.tint(Color.green)
				.frame(width: 28, height: 28)
				Spacer()
				Text("Voice Message")
				Spacer()
				Button {
					store.send(.onTapCloseButton)
				} label: {
					Image(systemName: "xmark")
						.tint(Color.gray.opacity(0.8))
				}
				.frame(width: 30, height: 30)
			}
			.padding(.horizontal)
			.frame(height: 36)

			VStack(spacing: 0) {
				Spacer()
				Rectangle()
					.fill(Color.green)
					.frame(height: 3)
					.animation(.linear, value: store.playProgress)
					.mask {
						Rectangle()
							.frame(maxWidth: .infinity, alignment: .leading)
							.frame(height: 3)
							.scaleEffect(x: store.playProgress, y: 1, anchor: .leading)
							.animation(.smooth, value: store.playProgress)
					}
			}
			.frame(height: 3)
		}
		.frame(maxWidth: .infinity)
		.frame(height: 36)
	}
}

#Preview {
	AudioPlayerView(
		store: Store(
			initialState: AudioPlayerReducer.State(),
			reducer: { AudioPlayerReducer() }
		)
	)
}
