import Dependencies

public extension DependencyValues {
	var hapticsClient: HapticsClient {
		get { self[HapticsClient.self] }
		set { self[HapticsClient.self] = newValue }
	}
}
