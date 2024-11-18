import Dependencies

extension DependencyValues {
	public var audioPlayerClient: AudioPlayerClient {
		get { self[AudioPlayerClient.self] }
		set { self[AudioPlayerClient.self] = newValue }
	}
}
