import Dependencies

extension DependencyValues {
	public var uploader: FilebaseFileUploaderClient {
		get { self[FilebaseFileUploaderClient.self] }
		set { self[FilebaseFileUploaderClient.self] = newValue }
	}
}
