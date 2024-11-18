import SwiftUI
import Appearance

public struct CancelButton: View {
	let action: () -> Void
	public init(action: @escaping () -> Void) {
		self.action = action
	}
	public var body: some View {
		Button {
			action()
		} label: {
			Image(systemName: "xmark")
				.scaledToFit()
				.imageScale(.small)
				.padding(5)
				.foregroundStyle(.white)
				.background(Color.white.opacity(0.5))
				.clipShape(Circle())
				.shadow(radius: 5)
				.padding(2)
				.bold()
		}
	}
}

#Preview {
	CancelButton {
		
	}
}
