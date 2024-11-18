import Foundation
import Dependencies

extension DependencyValues {
	public var dateFormattClient: DateFormattClient {
		get { self[DateFormattClient.self] }
		set { self[DateFormattClient.self] = newValue }
	}
}
