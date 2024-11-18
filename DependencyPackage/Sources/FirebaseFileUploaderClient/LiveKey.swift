import Dependencies
import FirebaseFileUpload
import FirebaseStorage
import Foundation
import StorageClient
import UIKit

extension FilebaseFileUploaderClient: DependencyKey {
	public static var liveValue = FilebaseFileUploaderClient(
		uploadContent: { uploadType in
			AsyncThrowingStream { continuation in
				Task {
					let fileName = UUID().uuidString
					@Dependency(\.storageClient) var storageClient
					let fileRef: StorageReference
					var thumbnailRef: StorageReference?
					var image: UIImage?
					var fileId: String?
					var thumbnail: UIImage?
					var fileURL: URL?
					var thumbnailURL: URL?
					switch uploadType {
					case let .profile(profileImage):
						fileRef = storageClient.profileImageRef().child(fileName)
						image = profileImage
					case let .photoMessage(photoFileId, photoImage):
						fileRef = storageClient.photoMessagesRef().child(fileName)
						fileId = photoFileId
						image = photoImage
					case let .videoMessage(videoFileId, thumbnailImage, videoFileURL):
						fileRef = storageClient.videoMessagesRef().child(fileName)
						fileId = videoFileId
						fileURL = videoFileURL
						thumbnail = thumbnailImage
						thumbnailRef = storageClient.photoMessagesRef().child("\(fileName)_thumbnail")
					case let .audioMessage(audioFileId, audioFileURL, _):
						fileRef = storageClient.audioMessagesRef().child(fileName)
						fileId = audioFileId
						fileURL = audioFileURL
					}
					do {
						if let imageData = image?.jpegData(compressionQuality: 0.5) {
							_ = try await fileRef.putDataAsync(imageData, metadata: nil) { progress in
								if let progress {
									let percentage = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
									continuation.yield(UploadFileResult.progress(fileId: fileId, progress: percentage))
								}
							}
						}
						// MARK: - upload file (video, audio)
						if let fileURL, let fileId {
							_ = try await fileRef.putFileAsync(from: fileURL, metadata: nil) { progress in
								if let progress {
									let percentage = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
									debugPrint("UploadContent Progress: \(percentage)")
									continuation.yield(UploadFileResult.progress(fileId: fileId, progress: percentage))
								}
							}
						}
						let url = try await fileRef.downloadURL()
						
						// MARK: - upload thumbnail
						if let thumbnailRef, let thumbnailData = thumbnail?.jpegData(compressionQuality: 0.5) {
							_ = try await thumbnailRef.putDataAsync(thumbnailData, metadata: nil) { progress in
								if let progress {
									let percentage = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
									continuation.yield(.progress(fileId: fileId, progress: percentage))
								}
							}
							thumbnailURL = try await thumbnailRef.downloadURL()
						}
						continuation.yield(UploadFileResult.completion(fileId: fileId, thumbnailUrl: thumbnailURL, fileUrl: url))
						continuation.finish()
					} catch {
						continuation.finish(throwing: UploadError.failedToUploadContent("Failed to upload image"))
					}
					
				}
			}
		}
	)
}
