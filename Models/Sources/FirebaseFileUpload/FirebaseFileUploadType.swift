import Foundation
import UIKit

public enum UploadFileType {
	case profile(image: UIImage)
	case photoMessage(fileId: String, image: UIImage)
	case videoMessage(fileId: String, thumbnail: UIImage, fileURL: URL)
	case audioMessage(fileId: String, fileURL: URL, duration: TimeInterval)
}

public enum UploadFileResult {
	case progress(fileId: String?, progress: Double)
	case completion(fileId: String?, thumbnailUrl: URL?, fileUrl: URL)
}

public enum UploadError: Error {
	case failedToUploadContent(_ description: String)
}

extension UploadError: LocalizedError {
	public var errorDescription: String? {
		switch self {
		case let .failedToUploadContent(description):
			return description
		}
	}
}
