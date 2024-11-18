import SwiftUI
import RswiftResources
import UIKit

public struct Appearance {
	public struct Colors {
		public static let accentColor = Color(R.color.accentColor)
		public static let whatsAppWhite = Color(R.color.whatsAppWhite)
		public static let whatsAppBlack = Color(R.color.whatsAppBlack)
		public static let bubbleGreen = Color(R.color.bubbleGreen)
		public static let bubbleWhite = Color(R.color.bubbleWhite)
		public static let whatsAppGrey = Color(R.color.whatsAppGray)
	}
	public struct Images {
		public static let communities = Image(R.image.communities)
		public static let circle = Image(R.image.circle)
		public static let plus = Image(R.image.plus)
		public static let qrCode = Image(R.image.qrcode)
		public static let messageOutgoingTail = Image(R.image.outgoingTail)
		public static let messageIncomingTail = Image(R.image.incomingTail)
		public static let messageSeen = Image(R.image.seen)
		public static let stubImage0 = Image(R.image.stubImage0)
		public static let stubImage1 = Image(R.image.stubImage1)
		public static let whatsApp = Image(R.image.whatsapp)
		public static let chatBackground = UIImage(resource: R.image.chatbackground)
	}
	public static let bundle = Bundle.module
}
