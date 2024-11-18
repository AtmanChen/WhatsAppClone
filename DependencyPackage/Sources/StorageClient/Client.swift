import Foundation
import FirebaseStorage
import DependenciesMacros

public struct StorageClient {
	public var storageRef: @Sendable () -> StorageReference
	public var profileImageRef: @Sendable () -> StorageReference
	public var photoMessagesRef: @Sendable () -> StorageReference
	public var videoMessagesRef: @Sendable () -> StorageReference
	public var audioMessagesRef: @Sendable () -> StorageReference
}
