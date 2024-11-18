import Foundation
import Dependencies

extension DependencyValues {
	public var storageClient: StorageClient {
		get { self[StorageClient.self] }
		set { self[StorageClient.self] = newValue } 
	}
}
