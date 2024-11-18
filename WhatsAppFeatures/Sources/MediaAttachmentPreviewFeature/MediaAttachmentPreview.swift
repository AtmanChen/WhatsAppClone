import Appearance
import CommonComponents
import ComposableArchitecture
import MediaAttachment
import PhotosUI
import SwiftUI
import UI_Extensions
import AudioRecorderClient

@Reducer
public struct MediaAttachmentPreviewReducer {
	public init() {}
	@ObservableState
	public struct State: Equatable {
		public var selectedMedia: IdentifiedArrayOf<MediaAttachment>
		public var isAttachmentsEmpty: Bool {
			selectedMedia.isEmpty
		}
		public init(selectedMedia: [MediaAttachment]) {
			self.selectedMedia = IdentifiedArray(uniqueElements: selectedMedia)
		}

//		public mutating func updateSelectedMedia(_ updateSelectedMedia: [MediaAttachment]) {
////			self.selectedMedia = IdentifiedArray(uniqueElements: updateSelectedMedia)
//			for media in updateSelectedMedia {
//				self.selectedMedia.updateOrAppend(media)
//			}
//		}
	}

	public enum Action {
		case clearAttachments
		case didTapRemoveButton(MediaAttachment)
		case didTapPlayAttachment(MediaAttachment)
		case delegate(Delegate)
		case updateSelectedMedia([MediaAttachment])
		
		public enum Delegate {
			case didTapRemoveButton(MediaAttachment, Bool)
			case playAttachment(MediaAttachment)
			case clearAttachmentsDone
		}
	}
	
	@Dependency(\.audioRecorder.deleteAudioRecordingAt) var deleteAudioRecording

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .clearAttachments:
				state.selectedMedia.removeAll()
				return .send(.delegate(.clearAttachmentsDone))
			case .delegate:
				return .none
			case let .didTapRemoveButton(mediaAttachment):
				state.selectedMedia.remove(id: mediaAttachment.id)
				return .run { [isEmpty = state.selectedMedia.isEmpty, mediaAttachment] send in
					if let url = mediaAttachment.playUrl {
						try deleteAudioRecording(url)
					}
					await send(.delegate(.didTapRemoveButton(mediaAttachment, isEmpty)))
				}
			case let .didTapPlayAttachment(attachment):
				return .send(.delegate(.playAttachment(attachment)), animation: .bouncy)
			case let .updateSelectedMedia(mediaAttachments):
				for media in mediaAttachments {
					state.selectedMedia.updateOrAppend(media)
				}
				return .none
			}
		}
	}
}

public struct MediaAttachmentPreview: View {
	@Bindable var store: StoreOf<MediaAttachmentPreviewReducer>
	public init(store: StoreOf<MediaAttachmentPreviewReducer>) {
		self.store = store
	}

	public var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack {
				ForEach(self.store.selectedMedia) { media in
					self.thumbnailImageView(media)
				}
			}
			.padding(.horizontal)
		}
		.frame(height: Constants.listHeight)
		.frame(maxWidth: .infinity)
		.background(Appearance.Colors.whatsAppWhite)
	}
	
	private func thumbnailImageView(_ mediaAttachment: MediaAttachment) -> some View {
		Button {} label: {
			switch mediaAttachment {
			case .audio:
				self.audioAttachmentPreview(mediaAttachment.id, attachment: mediaAttachment)
			case .image, .video:
				if let thumbnail = mediaAttachment.displayThumbnail {
					Image(uiImage: thumbnail)
						.resizable()
						.scaledToFill()
						.frame(width: Constants.imageDimen, height: Constants.imageDimen)
						.clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
						.overlay(alignment: .topTrailing) {
							CancelButton {
								self.store.send(.didTapRemoveButton(mediaAttachment), animation: .bouncy)
							}
						}
						.overlay(alignment: .center) {
							if mediaAttachment.isPlayable {
								self.playButton("play.fill", attachment: mediaAttachment)
							}
						}
				}
			}
		}
	}
	
	private func playButton(_ title: String, attachment: MediaAttachment) -> some View {
		Button {
			store.send(.didTapPlayAttachment(attachment))
		} label: {
			Image(systemName: title)
				.scaledToFit()
				.imageScale(.medium)
				.padding(6)
				.foregroundStyle(.white)
				.background(Color.white.opacity(0.5))
				.clipShape(Circle())
				.shadow(radius: 5)
				.padding(2)
				.bold()
		}
	}
	
	private func audioAttachmentPreview(_ id: String, attachment: MediaAttachment) -> some View {
		ZStack {
			LinearGradient(colors: [.green, .green.opacity(0.8), .teal], startPoint: .topLeading, endPoint: .bottom)
			self.playButton("mic.fill", attachment: attachment)
				.padding(.bottom)
		}
		.frame(width: Constants.imageDimen * 2, height: Constants.imageDimen)
		.clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
		.overlay(alignment: .topTrailing) {
			CancelButton {
				self.store.send(.didTapRemoveButton(attachment), animation: .bouncy)
			}
		}
		.overlay(alignment: .bottomLeading) {
			Text("Text mp3 file name here")
				.lineLimit(1)
				.font(.caption)
				.padding(2)
				.frame(maxWidth: .infinity, alignment: .center)
				.foregroundStyle(.white)
				.background(Color.white.opacity(0.5))
		}
	}
}

extension MediaAttachmentPreview {
	enum Constants {
		static let listHeight: CGFloat = 100
		static let imageDimen: CGFloat = 80
	}
}

// #Preview {
//	MediaAttachmentPreview(
//		store: Store(
//			initialState: MediaAttachmentPreviewReducer.State(photoPickerItems: []),
//			reducer: { MediaAttachmentPreviewReducer() }
//		)
//	)
// }
