import SwiftUI
import AVKit
import CommonComponents

public struct MediaPlayerView: View {
	let player: AVPlayer
	let dismiss: () -> Void
	public init(player: AVPlayer, dismiss: @escaping () -> Void) {
		self.player = player
		self.dismiss = dismiss
	}
	public var body: some View {
		VideoPlayer(player: player)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.ignoresSafeArea()
			.overlay(alignment: .topLeading) {
				CancelButton {
					dismiss()
				}
				.padding()
			}
			.onAppear {
				player.play()
			}
			.onDisappear {
				player.pause()
				player.replaceCurrentItem(with: nil)
			}
	}
}
