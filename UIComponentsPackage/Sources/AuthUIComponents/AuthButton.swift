import SwiftUI

public struct AuthButton: View {
	let title: String
	let icon: Image
	let isDisabled: Bool
	let onTap: () -> Void
	public init(
		title: String,
		icon: Image,
		isDisabled: Bool,
		onTap: @escaping () -> Void
	) {
		self.title = title
		self.icon = icon
		self.isDisabled = isDisabled
		self.onTap = onTap
	}
	public var body: some View {
		Button {
			onTap()
		} label: {
			HStack {
				Text(title)
				icon
			}
			.font(.headline)
			.foregroundStyle(textColor)
			.padding()
			.frame(maxWidth: .infinity)
			.background(backgroundColor)
			.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
			.shadow(color: .green.opacity(0.2), radius: 10)
			.padding(.horizontal, 32)
		}
		.disabled(isDisabled)
	}
	private var backgroundColor: Color {
		isDisabled ? Color.white.opacity(0.3) : Color.white
	}
	private var textColor: Color {
		isDisabled ? Color.white : Color.green
	}
}
