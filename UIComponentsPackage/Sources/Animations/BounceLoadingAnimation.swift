import SwiftUI

public struct BouncingLoadingAnimation: ViewModifier {
		let amplitude: CGFloat
		let upDuration: Double
		let pauseDuration: Double
		let downDuration: Double
		
		@State private var offset: CGFloat = 0
		
		init(
				amplitude: CGFloat = 10,
				upDuration: Double = 0.2,
				pauseDuration: Double = 0.1,
				downDuration: Double = 0.1
		) {
				self.amplitude = amplitude
				self.upDuration = upDuration
				self.pauseDuration = pauseDuration
				self.downDuration = downDuration
		}
		
		public func body(content: Content) -> some View {
				content
						.offset(y: offset)
						.onAppear {
								withAnimation(animation) {
										offset = -amplitude
								}
						}
		}
		
		private var animation: Animation {
				let totalDuration = upDuration + pauseDuration + downDuration
				
			return Animation.timingCurve(0.2, 0.68, 0.6, 0.8, duration: totalDuration)
						.repeatForever(autoreverses: false)
		}
}

public extension View {
	func bouncingLoadingAnimation(
		amplitude: CGFloat = 4
	) -> some View {
		modifier(BouncingLoadingAnimation(
			amplitude: amplitude,
			upDuration: 0.4,
			pauseDuration: 0.4,
			downDuration: 1.0
		))
	}
}
