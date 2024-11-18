import DependenciesMacros
import Foundation

@DependencyClient
public struct HapticsClient {
	public enum Style {
		case light
		case medium
		case heavy
		case error
		case success
		case warning
	}

	public var impact: (_ style: Style) -> Void
}
