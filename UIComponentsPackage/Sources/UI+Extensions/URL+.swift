import Foundation
import AVFoundation
import UIKit

extension URL {
	public func generateVideoThumbnail() async throws -> UIImage? {
		let asset = AVAsset(url: self)
		let imageGenerator = AVAssetImageGenerator(asset: asset)
		imageGenerator.appliesPreferredTrackTransform = true
		let time = CMTime(seconds: 1, preferredTimescale: 60)
		return try await withCheckedThrowingContinuation { continuation in
			imageGenerator.generateCGImageAsynchronously(for: time) { cgImage, time, error in
				if let cgImage {
					let uiImage = UIImage(cgImage: cgImage)
					continuation.resume(returning: uiImage)
				} else {
					continuation.resume(throwing: error ?? NSError(domain: "", code: 0))
				}
			}
		}
	}
}
