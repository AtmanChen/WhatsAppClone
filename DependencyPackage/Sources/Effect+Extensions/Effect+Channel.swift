import ChannelClient
import ChannelModels
import ComposableArchitecture
import Foundation

public extension Effect {
	static func listenToChannelInfo(
		channelsClient: ChannelClient = .liveValue,
		channelId: String,
		mapToAction: @escaping (ChannelItem) -> Action
	) -> Effect {
		.run { [channelId] send in
			await withTaskCancellation(id: "channel_\(channelId)") {
				do {
					for try await channel in channelsClient.addChannelInfoListener(channelId).eraseToThrowingStream() {
						if let channel {
							await send(mapToAction(channel))
						}
					}
				} catch is CancellationError {
					// 任务被取消，不需要特殊处理
					debugPrint("channel_\(channelId) canceled")
				} catch {
					// 处理其他可能的错误
				}
			}
		}
	}

	static func listenToCurrentUserChannels(
		channelsClient: ChannelClient = .liveValue,
		mapToAction: @escaping ([ChannelItem]) -> Action
	) -> Effect {
		.run { send in
			for await channelItems in channelsClient.addCurrentUserChannelsListener() {
				await send(mapToAction(channelItems.sorted(by: { $0.lastMessageTimestamp < $1.lastMessageTimestamp })), animation: .snappy)
			}
		}
	}
}
