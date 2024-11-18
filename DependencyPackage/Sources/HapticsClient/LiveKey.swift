import Dependencies
import Foundation
import UIKit

extension HapticsClient: DependencyKey {
	public static var liveValue = HapticsClient(
		impact: { style in
			switch style {
			case .light:
				let generator = UIImpactFeedbackGenerator(style: .light)
				generator.impactOccurred()
			case .medium:
				let generator = UIImpactFeedbackGenerator(style: .medium)
				generator.impactOccurred()
			case .heavy:
				let generator = UIImpactFeedbackGenerator(style: .heavy)
				generator.impactOccurred()
			case .error:
				let generator = UINotificationFeedbackGenerator()
				generator.notificationOccurred(.error)
			case .success:
				let generator = UINotificationFeedbackGenerator()
				generator.notificationOccurred(.success)
			case .warning:
				let generator = UINotificationFeedbackGenerator()
				generator.notificationOccurred(.warning)
			}
		}
	)
}
