import UIKit
import MediaAttachment
import Appearance
import SwiftUI

extension MediaAttachment {
	public var displayThumbnail: UIImage? {
		switch self {
		case .image(_, let thumbnail):
			return thumbnail
		case .video(_, let thumbnail, _):
			return thumbnail
		default: return nil
		}
	}
	public var isPlayable: Bool {
		switch self {
		case .audio: return true
		case .image: return false
		case .video: return true
		}
	}
}

extension View {
	public func formatTimeInterval(_ interval: TimeInterval) -> some View {
		let minutes = Int(interval) / 60
		let seconds = Int(interval) % 60
		return Text(String(format: "%02d:%02d", minutes, seconds))
			.font(.body.monospacedDigit())
			.fontWeight(.semibold)
			.foregroundColor(Appearance.Colors.whatsAppBlack)
	}
}
