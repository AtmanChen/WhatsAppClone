import AudioRecorderClient
import ComposableArchitecture
import SwiftUI
import Appearance
import UI_Extensions

@Reducer
public struct ChatAudioRecordingIndicator {
	public init() {}
	@ObservableState
	public struct State: Equatable {
		var duration: TimeInterval = 0
		var indicatorScale: CGFloat = 1.0
		public init() {}
	}

	public enum Action: BindableAction {
		case audioRecorderDidStart(Result<Bool, Error>)
		case stopAudioRecorder
		case binding(BindingAction<State>)
		case task
		case timerUpdate
		case delegate(Delegate)

		public enum Delegate {
			case successToStartAudioRecorder
			case failedToStartAudioRecorder(Error)
			case audioRecorderDidStopped(URL?, TimeInterval?)
		}
	}

	public struct Failed: Equatable, Error {}
	@Dependency(\.audioRecorder) var audioRecorder
	@Dependency(\.continuousClock) var clock
	public var body: some ReducerOf<Self> {
		BindingReducer()
		Reduce {
			state,
				action in
			switch action {
			case let .audioRecorderDidStart(result):
				debugPrint("Audio Recorder Did Start: \(result)")
				switch result {
				case .success(true):
					state.indicatorScale = 1.5
					return .send(.delegate(.successToStartAudioRecorder))
				case .success(false):
					return .run { send in
						await audioRecorder.pauseRecording()
						await send(.delegate(.failedToStartAudioRecorder(Failed())))
					}
				case let .failure(error):
					return .send(.delegate(.failedToStartAudioRecorder(error)))
				}
			case .binding:
				return .none
			case .delegate:
				return .none
			case .stopAudioRecorder:
				return .run { [duration = state.duration] send in
					let fileURL = await audioRecorder.fileURL()
					await audioRecorder.stopRecording()
					await send(.delegate(.audioRecorderDidStopped(fileURL, duration)))
				}
			case .task:
				return .run { send in
					async let audioRecorderStarted: Void = send(
						.audioRecorderDidStart(
							Result {
								try await audioRecorder.startRecording()
							}
						)
					)
					async let timerUpdate: Void = {
						for await _ in clock.timer(interval: .seconds(1)) {
							await send(.timerUpdate)
						}
					}()
					_ = await (audioRecorderStarted, timerUpdate)
				}
			case .timerUpdate:
				state.duration += 1
				return .none
			}
		}
	}
}

let dateComponentsFormatter: DateComponentsFormatter = {
	let formatter = DateComponentsFormatter()
	formatter.unitsStyle = .positional
	formatter.allowedUnits = [.minute, .second]
	formatter.zeroFormattingBehavior = .pad
	return formatter
}()

public struct ChatAudioRecordingIndicatorView: View {
	@Bindable var store: StoreOf<ChatAudioRecordingIndicator>
	public init(store: StoreOf<ChatAudioRecordingIndicator>) {
		self.store = store
	}

	public var body: some View {
		HStack {
			Image(systemName: "circle.fill")
				.foregroundStyle(.red)
				.font(.caption)
				.scaleEffect(store.indicatorScale)
				.animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: store.indicatorScale)
			Text("Recording Audio")
				.font(.callout)
			Spacer()
			formatTimeInterval(store.duration)
				
		}
		.padding(6)
		.clipShape(Capsule())
		.task {
			await store.send(.task).finish()
		}
	}
}



#Preview {
	ChatAudioRecordingIndicatorView(
		store: Store(
			initialState: ChatAudioRecordingIndicator.State(),
			reducer: { ChatAudioRecordingIndicator() }
		)
	)
}
