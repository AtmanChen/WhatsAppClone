import Foundation
import Dependencies
import DependenciesMacros

@DependencyClient
public struct DateFormattClient {
	public var dayOrTimeRepresentation: @Sendable (Date) -> String = { _ in "" }
	public var timeRepresentation: @Sendable (Date) -> String = { _ in "" }
	public var stringWithFormat: @Sendable (String) -> String = { _ in "" }
	public var messageHeaderRelativeRepresentation: @Sendable (Date) -> String  = { _ in "" }
}
