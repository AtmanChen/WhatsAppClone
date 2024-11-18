import Dependencies

extension DependencyValues {
	public var channelClient: ChannelClient {
		get { self[ChannelClient.self] }
		set { self[ChannelClient.self] = newValue} 
	}
}
