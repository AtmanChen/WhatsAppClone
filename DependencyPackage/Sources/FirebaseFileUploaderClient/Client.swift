import Foundation
import DependenciesMacros
import FirebaseFileUpload

@DependencyClient
public struct FilebaseFileUploaderClient {
	public var uploadContent: @Sendable (UploadFileType) -> AsyncThrowingStream<UploadFileResult, Error> = { _ in .never }
}
