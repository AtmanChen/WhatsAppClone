import ComposableArchitecture

@Reducer
public struct ChatPartnerPathReducer {
	public func reduce(
		into state: inout ChatPartnerReducer.State,
		action: ChatPartnerReducer.Action
	) -> Effect<ChatPartnerReducer.Action> {
		switch action {
		case let .path(.element(_, action)):
			switch action {
			case let .addGroupMembers(.delegate(.onTapNextStepButton(sharedSelectedUsers))):
				state.path.append(.createGroupChat(ChatPartnerCreateGroupChatReducer.State(selectedUsers: sharedSelectedUsers)))
				return .none
			case let .createGroupChat(.delegate(.createChannelResponse(channel))):
				return .send(.delegate(.jumpToChat(channel)))
			default: return .none
			}
		case let .partnerPicker(.delegate(.onTapChatOption(option))):
			switch option {
			case .newGroup:
				state.path.append(.addGroupMembers(ChatPartnerAddGroupMembersReducer.State()))
				return .none
			default: return .none
			}
		default: return .none
		}
	}
}
