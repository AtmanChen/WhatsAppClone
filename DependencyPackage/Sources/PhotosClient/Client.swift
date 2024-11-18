import Photos
import UIKit
import DependenciesMacros
import Dependencies

@DependencyClient
public struct PhotosClient: Sendable {
	public var requestAuthorization: @Sendable (PHAccessLevel) async -> PHAuthorizationStatus = { _ in .notDetermined }
	public var authorizationStatus: @Sendable (PHAccessLevel) -> PHAuthorizationStatus = { _ in .notDetermined }
	public var fetchAssets: @Sendable (PHFetchOptions?) -> [PHAsset] = { _ in [] }
	public var requestImage: @Sendable (PHAsset, CGSize, PHImageContentMode, PHImageRequestOptions?) async -> AsyncStream<(UIImage?, [AnyHashable: Any]?)> = { _,_,_,_  in .never }
	public var performChanges: @Sendable (_ changeBlock: @escaping () -> Void) async throws -> Void = { _ in }
}
