//
//  File.swift
//
//
//  Created by Anderson  on 2024/9/14.
//

import Appearance
import CallTabScreenFeature
import ChatTabScreenFeature
import CommunityTabScreenFeature
import ComposableArchitecture
import Foundation
import SettingsTabScreenFeature
import SwiftUI
import UpdateTabScreenFeature

enum Tab: String, CaseIterable, Identifiable {
	case updates, calls, communities, chats, settings
	var title: String {
		rawValue.capitalized
	}

	var icon: String {
		switch self {
		case .updates:
			return "circle.dashed.inset.filled"
		case .calls:
			return "phone"
		case .communities:
			return "person.3"
		case .chats:
			return "message"
		case .settings:
			return "gear"
		}
	}

	var id: Self { self }
}

@Reducer
public struct MainTab {
	public init() {}

	@ObservableState
	public struct State: Equatable {
		var tabs: [Tab] = Tab.allCases
		var callScreen = CallTab.State()
		var communityScreen = CommunityTab.State()
		var updateScreen = UpdateTab.State()
		var chatScreen = ChatTab.State()
		var settingsScreen = SettingsTab.State()
		public init() {}
	}

	public enum Action: BindableAction {
		case binding(BindingAction<State>)
		case callScreen(CallTab.Action)
		case communityScreen(CommunityTab.Action)
		case chatScreen(ChatTab.Action)
		case settingsScreen(SettingsTab.Action)
		case updateScreen(UpdateTab.Action)
	}

	public var body: some ReducerOf<Self> {
		BindingReducer()
		Scope(state: \.updateScreen, action: \.updateScreen) {
			UpdateTab()
		}
		Scope(state: \.callScreen, action: \.callScreen) {
			CallTab()
		}
		Scope(state: \.communityScreen, action: \.communityScreen) {
			CommunityTab()
		}
		Scope(state: \.chatScreen, action: \.chatScreen) {
			ChatTab()
		}
		Scope(state: \.settingsScreen, action: \.settingsScreen) {
			SettingsTab()
		}
		Reduce { _, action in
			switch action {
			case .binding:
				return .none
			case .callScreen:
				return .none
			case .communityScreen:
				return .none
			case .chatScreen:
				return .none
			case .settingsScreen:
				return .none
			case .updateScreen:
				return .none
			}
		}
	}
}

public struct MainTabView: View {
	let store: StoreOf<MainTab>
	public init(store: StoreOf<MainTab>) {
		self.store = store
		makeTabBarOpaue()
		let thumbImage = UIImage(systemName: "circle.fill")
		UISlider.appearance()
			.setThumbImage(thumbImage, for: .normal)
	}

	public var body: some View {
		TabView {
			UpdateTabScreen(
				store: store.scope(state: \.updateScreen, action: \.updateScreen)
			)
			.tabItem {
				Label(
					title: { Text(Tab.updates.title) },
					icon: { Image(systemName: Tab.updates.icon) }
				)
			}

			CallTabScreen(
				store: store.scope(state: \.callScreen, action: \.callScreen)
			)
			.tabItem {
				Label(
					title: { Text(Tab.calls.title) },
					icon: { Image(systemName: Tab.calls.icon) }
				)
			}

			CommunityTabScreen(
				store: store.scope(state: \.communityScreen, action: \.communityScreen)
			)
			.tabItem {
				Label(
					title: { Text(Tab.communities.title) },
					icon: { Image(systemName: Tab.communities.icon) }
				)
			}

			ChatTabScreen(store: store.scope(state: \.chatScreen, action: \.chatScreen))
				.tabItem {
					Label(
						title: { Text(Tab.chats.title) },
						icon: { Image(systemName: Tab.chats.icon) }
					)
				}

			SettingsTabScreen(store: store.scope(state: \.settingsScreen, action: \.settingsScreen))
				.tabItem {
					Label(
						title: { Text(Tab.settings.title) },
						icon: { Image(systemName: Tab.settings.icon) }
					)
				}
		}
	}

	private func makeTabBarOpaue() {
		let appearance = UITabBarAppearance()
		appearance.configureWithOpaqueBackground()
		UITabBar.appearance().standardAppearance = appearance
		UITabBar.appearance().scrollEdgeAppearance = appearance
	}
}

#Preview {
	MainTabView(
		store: Store(
			initialState: MainTab.State(),
			reducer: { MainTab() }
		)
	)
}
