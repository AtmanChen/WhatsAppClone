@testable import LaunchFeature
import SnapshotTesting
import ComposableArchitecture
import XCTest
import SwiftUI

final class WhatsAppFeaturesTests: XCTestCase {
	func testExample() throws {
		// XCTest Documentation
		// https://developer.apple.com/documentation/xctest

		// Defining Test Cases and Test Methods
		// https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
	}
	
	func testBasics() {
		let launchScreen = LaunchScreen(
			store: Store(
				initialState: LaunchReducer.State(),
				reducer: { LaunchReducer() }
			)
		)
		assertSnapshot(of: launchScreen, as: .image(perceptualPrecision: 0.98, layout: .device(config: .iPhoneXsMax)))
	}
}
