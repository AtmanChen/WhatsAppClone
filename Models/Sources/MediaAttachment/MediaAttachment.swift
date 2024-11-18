import Foundation
import UIKit

public enum MediaAttachment: Identifiable, Equatable {
	case audio(url: URL, duration: TimeInterval)
	case image(id: String, thumbnail: UIImage)
	case video(id: String, thumbnail: UIImage, url: URL)
	public var id: String {
		switch self {
		case .audio(let url, _):
			return url.absoluteString
		case .image(let id, _):
			return id
		case .video(let id, _, _):
			return id
		}
	}
	public var playUrl: URL? {
		switch self {
		case let .audio(url, _):
			return url
		case let .video(_, _, url):
			return url
		default: return nil
		}
	}
	public var thumbnail: UIImage? {
		switch self {
		case .audio: return nil
		case .image(_, let thumbnail): return thumbnail
		case .video(_, let thumbnail, _): return thumbnail
		}
	}
}
