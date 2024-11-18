import Dependencies

extension DependencyValues {
	public var audioRecorder: AudioRecorderClient {
		get { self[AudioRecorderClient.self] }
		set { self[AudioRecorderClient.self] = newValue }
	}
}

//extension DependencyValues {
//	public var audioPlayer: AudioPlayer {
//		get { self[AudioPlayer.self] }
//		set { self[AudioPlayer.self] = newValue }
//	}
//}
