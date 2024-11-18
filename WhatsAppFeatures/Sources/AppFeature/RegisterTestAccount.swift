import ComposableArchitecture
import FirebaseAuthClient

@Reducer
public struct RegisterTestAccount {
	@Dependency(\.firebaseAuthClient) var firebaseAuthClient
	public func reduce(into state: inout AppReducer.State, action: AppReducer.Action) -> Effect<AppReducer.Action> {
		if case .appDelegate(.didFinishLaunching) = action {
			return .run { _ in
				for email in testEmails {
					try await firebaseAuthClient.createAccount(email: email, username: email.replacingOccurrences(of: "@test.com", with: ""), password: "123456")
				}
			}
		}
		return .none
	}
}

private let testEmails = [
	"QA1@test.com",
	"QA2@test.com",
	"QA3@test.com",
	"QA4@test.com",
	"QA5@test.com",
	"QA6@test.com",
	"QA7@test.com",
	"QA8@test.com",
	"QA9@test.com",
	"QA10@test.com",
	"QA11@test.com",
	"QA12@test.com",
	"QA13@test.com",
	"QA14@test.com",
	"QA15@test.com",
	"QA16@test.com",
	"QA17@test.com",
	"QA18@test.com",
	"QA19@test.com",
]

