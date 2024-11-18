import SwiftUI
import Appearance

public struct AuthHeaderView: View {
	public init() {}
	public var body: some View {
		HStack {
			Appearance.Images.whatsApp
				.resizable()
				.frame(width: 40, height: 40)
			Text("WhatsApp")
				.font(.largeTitle)
				.foregroundStyle(.white)
				.fontWeight(.semibold)
		}
	}
}
