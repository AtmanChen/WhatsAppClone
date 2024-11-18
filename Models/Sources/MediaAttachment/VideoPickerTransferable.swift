import SwiftUI

public struct VideoPickerTransferable: Transferable, Identifiable, Equatable {
	public let url: URL
	public var id: String {
		url.absoluteString
	}
	public static var transferRepresentation: some TransferRepresentation {
		FileRepresentation(contentType: .movie) { exportingFile in
				.init(exportingFile.url, allowAccessingOriginalFile: true)
		} importing: { receivedTransferredFile in
			do {
				let originalFile = receivedTransferredFile.file
				let uniqueFileName = "\(UUID().uuidString).mov"
				let copiedFile = URL.documentsDirectory.appendingPathComponent(uniqueFileName)
				try FileManager.default.copyItem(at: originalFile, to: copiedFile)
				return .init(url: copiedFile)
			} catch {
				print(error)
				throw error
			}
		}
	}
}
