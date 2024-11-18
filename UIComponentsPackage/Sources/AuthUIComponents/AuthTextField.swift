import SwiftUI

public struct AuthTextField: View {
	let icon: Image
	let placeholder: String
	let isSecure: Bool
	let keyboardType: UIKeyboardType
	@Binding var text: String
	public init(
		icon: Image,
		placeholder: String,
		isSecure: Bool,
		keyboardType: UIKeyboardType,
		text: Binding<String>
	) {
		self.icon = icon
		self.placeholder = placeholder
		self.isSecure = isSecure
		self.keyboardType = keyboardType
		self._text = text
	}
	public var body: some View {
		HStack {
			icon
				.fontWeight(.semibold)
				.frame(width: 30)
			if isSecure {
				SecureField(placeholder, text: $text)
					.keyboardType(keyboardType)
			} else {
				TextField(placeholder, text: $text)
					.keyboardType(keyboardType)
			}
		}
		.foregroundStyle(.white)
		.padding()
		.background(Color.white.opacity(0.3))
		.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
		.padding(.horizontal, 32)
	}
}
