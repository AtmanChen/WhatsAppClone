//
//  File.swift
//
//
//  Created by Anderson  on 2024/9/16.
//

import SwiftUI

public struct BreathingAnimation: ViewModifier {
	let minScale: CGFloat
	let maxScale: CGFloat
	let duration: Double

	@State private var isBreathing = false

	init(minScale: CGFloat = 0.8, maxScale: CGFloat = 1.2, duration: Double = 1.5) {
		self.minScale = minScale
		self.maxScale = maxScale
		self.duration = duration
	}

	public func body(content: Content) -> some View {
		content
			.scaleEffect(isBreathing ? maxScale : minScale)
			.animation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true), value: isBreathing)
			.onAppear {
				isBreathing = true
			}
	}
}

public extension View {
	func breathingAnimation(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 0.8) -> some View {
		modifier(BreathingAnimation(minScale: minScale, maxScale: maxScale, duration: duration))
	}
}
