import AVFoundation
import MediaAttachment
import PhotosUI
import SwiftUI

extension PhotosPickerItem: Identifiable {
	public var id: String {
		self.itemIdentifier ?? "\(self.hashValue)"
	}
}

public extension PhotosPickerItem {
	var isVideo: Bool {
		let videoUTypes: [UTType] = [
			.avi,
			.video,
			.mpeg2Video,
			.mpeg4Movie,
			.quickTimeMovie,
			.audiovisualContent,
			.mpeg,
			.appleProtectedMPEG4Video,
			.movie
		]
		return videoUTypes.contains(where: supportedContentTypes.contains)
	}
}

public extension PhotosPickerItem {
	func convertToImage() async -> UIImage? {
		guard let imageData = try? await loadTransferable(type: Data.self),
		      let image = UIImage(data: imageData)
		else {
			return nil
		}
		return image
	}
}

public extension Array where Element == PhotosPickerItem {
	func convertToMediaAttachment() async -> [MediaAttachment] {
		var mediaAttachments: [MediaAttachment] = []
		for photoItem in self {
			if photoItem.isVideo {
				if let movie = try? await photoItem.loadTransferable(type: VideoPickerTransferable.self), 
						let thumbnailImage = try? await movie.url.generateVideoThumbnail() {
					let videoAttachment = MediaAttachment.video(id: photoItem.id, thumbnail: thumbnailImage, url: movie.url)
					mediaAttachments.insert(videoAttachment, at: 0)
				}
			} else {
				guard let image = await photoItem.convertToImage() else {
					continue
				}
				mediaAttachments.insert(.image(id: photoItem.id, thumbnail: image), at: 0)
			}
		}
		return mediaAttachments
	}
}
