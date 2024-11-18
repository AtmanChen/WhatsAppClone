import Appearance
import AudioRecorderClient
import ComposableArchitecture
import Foundation
import MediaAttachment
import SwiftUI

@Reducer
public struct ChatTextInputArea {
	public enum RecorderPermission {
		case allowed
		case denied
		case notDetermined
	}
	
	@Reducer(state: .equatable)
	public enum Destination {
		case performAudioRecorderAlert(AlertState<ChatTextInputArea.Action.Alert>)
		case leavePageAlert(AlertState<ChatTextInputArea.Action.LeavePageAlert>)
	}
	
	public init() {}
	@ObservableState
	public struct State: Equatable {
		var inputMessage = ""
		var isMessageAttachmentsEmpty = true
		var focus: Field?
		var isSendButtonDisabled: Bool {
			(inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && isMessageAttachmentsEmpty) || isRecording
		}

		var audioRecordingIndicator: ChatAudioRecordingIndicator.State?
		var audioRecorderPermission: RecorderPermission = .notDetermined
		var isRecording: Bool {
			audioRecordingIndicator != nil
		}
		public enum Field: String, Hashable {
			case messageInput
		}
		@Presents var destination: Destination.State?
		public init() {}
	}

	public enum Action: BindableAction {
		case destination(PresentationAction<Destination.Action>)
		case audioRecordPermissionResponse(Bool)
		case dismissKeyborad
		case binding(BindingAction<State>)
		case audioRecordingIndicator(ChatAudioRecordingIndicator.Action)
		case onTapMediaAttachmentButton
		case onTapSendButton
		case onTapAudioRecordingButton
		case onTapNavigationBackButton
		case delegate(Delegate)
		case updateMessageAttachmentsIsEmpty(Bool)
		
		@CasePathable
		public enum Delegate {
			case onTapMediaAttachmentButton
			case onTapSendButton(String)
			case didStopAudioRecording(MediaAttachment)
			case confirmLeaving
		}
		
		@CasePathable
		public enum Alert {
			case ok
		}
		
		@CasePathable
		public enum LeavePageAlert {
			case cancelLeaving
			case confirmLeaving
		}
	}
	@Dependency(\.audioRecorder.stopRecordingAndDeleteAllFiles) var stopRecordingAndDeleteAllFile
	@Dependency(\.audioRecorder.pauseRecording) var pauseRecording
	@Dependency(\.audioRecorder.resumeRecording) var resumeRecording
	@Dependency(\.audioRecorder.requestRecordPermission) var requestAudioRecorderPermission
	public var body: some ReducerOf<Self> {
		BindingReducer()
		Reduce {
			state,
				action in
			switch action {
			case .destination(.dismiss):
				state.destination = nil
				return .none
			case .destination(.presented(.leavePageAlert(.cancelLeaving))):
				return .run { _ in
					await resumeRecording()
				}
			case .destination(.presented(.leavePageAlert(.confirmLeaving))):
				return .run { send in
					try await stopRecordingAndDeleteAllFile()
					await send(.delegate(.confirmLeaving))
				}
			case .destination:
				return .none
			case .dismissKeyborad:
				state.focus = nil
				return .none
			case .audioRecordingIndicator(.delegate(.successToStartAudioRecorder)):
				return .none
			case .audioRecordingIndicator(.delegate(.failedToStartAudioRecorder)):
				state.destination = .performAudioRecorderAlert(AlertState {
					TextState("Failed to start audio recording")
				})
				return .none
			case let .audioRecordingIndicator(.delegate(.audioRecorderDidStopped(url, duration))):
				if state.audioRecordingIndicator != nil {
					state.audioRecordingIndicator = nil
				}
				guard let url,
				      let duration,
				      duration > 1
				else {
					return .none
				}
				return .send(.delegate(.didStopAudioRecording(MediaAttachment.audio(url: url, duration: duration))))
			case let .audioRecordPermissionResponse(permission):
				state.audioRecorderPermission = permission ? .allowed : .denied
				if permission {
					state.audioRecordingIndicator = ChatAudioRecordingIndicator.State()
				} else {
					state.destination = .performAudioRecorderAlert(AlertState {
						TextState("Permission is required to record voice memos.")
					})
				}
				return .none
			case .binding:
				return .none
			case .onTapMediaAttachmentButton:
				return .send(.delegate(.onTapMediaAttachmentButton), animation: .easeInOut)
			case .onTapSendButton:
				let message = state.inputMessage
				state.inputMessage = ""
				return .send(.delegate(.onTapSendButton(message)))
			case .onTapAudioRecordingButton:
				if state.audioRecordingIndicator != nil {
					return .run { send in
						await send(.audioRecordingIndicator(.stopAudioRecorder))
					}
				} else {
					switch state.audioRecorderPermission {
					case .allowed:
						state.audioRecordingIndicator = ChatAudioRecordingIndicator.State()
						return .none
					case .denied:
						state.destination = .performAudioRecorderAlert(AlertState {
							TextState("Permission is required to record voice.")
						})
						return .none
					case .notDetermined:
						return .run { send in
							await send(.audioRecordPermissionResponse(await requestAudioRecorderPermission()))
						}
					}
				}
			case .onTapNavigationBackButton:
				if state.audioRecordingIndicator != nil {
					state.destination = .leavePageAlert(
						AlertState {
							TextState("Audio Recording is running")
						} actions: {
							ButtonState(role: .cancel, action: Action.LeavePageAlert.cancelLeaving) {
								TextState("Cancel")
							}
							ButtonState(role: .destructive, action: Action.LeavePageAlert.confirmLeaving) {
								TextState("It's OK")
							}
						} message: {
							TextState("Leave this page will drop your recording")
						}
					)
					return .run { _ in
						await pauseRecording()
					}
				}
				return .send(.delegate(.confirmLeaving))
			case let .updateMessageAttachmentsIsEmpty(isMessageAttachmentsEmpty):
				state.isMessageAttachmentsEmpty = isMessageAttachmentsEmpty
				return .none
			default: return .none
			}
		}
		.ifLet(\.audioRecordingIndicator, action: \.audioRecordingIndicator) {
			ChatAudioRecordingIndicator()
		}
		.ifLet(\.$destination, action: \.destination) {
			Destination.body
		}
	}
}

public struct ChatTextInputAreaView: View {
	@Bindable var store: StoreOf<ChatTextInputArea>
	@FocusState var focusedField: ChatTextInputArea.State.Field?
	public init(store: StoreOf<ChatTextInputArea>) {
		self.store = store
	}

	public var body: some View {
		HStack(alignment: .bottom, spacing: 5) {
			imagePickerButton()
				.padding(3)
			audioRecordButton()
			if let audioRecordingIndicatorStore = store.scope(state: \.audioRecordingIndicator, action: \.audioRecordingIndicator) {
				ChatAudioRecordingIndicatorView(store: audioRecordingIndicatorStore)
					.overlay(inputTextFieldBorder())
			} else {
				messageTextField()
			}
			sendMessageButton()
		}
		.padding(.bottom)
		.padding(.horizontal, 8)
		.padding(.top, 10)
		.background(Appearance.Colors.whatsAppWhite)
		.alert($store.scope(state: \.destination?.performAudioRecorderAlert, action: \.destination.performAudioRecorderAlert))
		.alert($store.scope(state: \.destination?.leavePageAlert, action: \.destination.leavePageAlert))
		.bind($store.focus, to: $focusedField)
	}
}

extension ChatTextInputAreaView {
	private func imagePickerButton() -> some View {
		Button {
			store.send(.onTapMediaAttachmentButton)
		} label: {
			Image(systemName: "photo.on.rectangle")
				.font(.system(size: 22))
		}
		.disabled(store.isRecording)
	}

	private func audioRecordButton() -> some View {
		Button {
			store.send(.onTapAudioRecordingButton)
		} label: {
			Image(systemName: store.isRecording ? "square.fill" : "mic.fill")
				.fontWeight(.heavy)
				.imageScale(.small)
				.foregroundStyle(.white)
				.padding(6)
				.background(store.isRecording ? .red : .blue)
				.clipShape(Circle())
				.padding(.horizontal, 3)
				.symbolEffect(.bounce, value: store.isRecording)
		}
	}

	private func messageTextField() -> some View {
		TextField("Input words here...", text: $store.inputMessage, axis: .vertical)
			.focused($focusedField, equals: .messageInput)
			.padding(4)
			.background(
				RoundedRectangle(cornerRadius: 20, style: .continuous)
					.fill(.thinMaterial)
			)
			.overlay(inputTextFieldBorder())
			
	}
	
	private func inputTextFieldBorder() -> some View {
		RoundedRectangle(cornerRadius: 20, style: .continuous)
			.stroke(Color(.systemGray5), lineWidth: 1)
	}
	
	private func sendMessageButton() -> some View {
		Button {
			store.send(.onTapSendButton)
		} label: {
			Image(systemName: "arrow.up")
				.fontWeight(.heavy)
				.foregroundStyle(.white)
				.padding(6)
				.background(Color.blue)
				.clipShape(Circle())
		}
		.disabled(store.isSendButtonDisabled || store.isRecording)
		.grayscale((store.isSendButtonDisabled || store.isRecording) ? 0.8 : 0)
	}
}

#Preview {
	ChatTextInputAreaView(
		store: Store(
			initialState: ChatTextInputArea.State(),
			reducer: { ChatTextInputArea() }
		)
	)
}
