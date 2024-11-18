//
//  File.swift
//  
//
//  Created by Anderson  on 2024/9/14.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import Appearance

enum CallHistory: String, CaseIterable, Identifiable {
	var id: Self { self }
	
	case all, missed
}

@Reducer
public struct CallTab {
	public init() {}
	@ObservableState
	public struct State: Equatable {
		public init() {}
		var searchText = ""
		var callHistory: CallHistory = .all
	}
	public enum Action: BindableAction {
		case binding(BindingAction<State>)
	}
	public var body: some ReducerOf<Self> {
		BindingReducer()
		Reduce { state, action in
			switch action {
			case .binding:
				return .none
			}
		}
	}
}

public struct CallTabScreen: View {
	@Bindable var store: StoreOf<CallTab>
	public init(store: StoreOf<CallTab>) {
		self.store = store
	}
	public var body: some View {
		NavigationStack {
			List {
				Section {
					CreateCallLinkSection()
				}
				Section {
					ForEach(0..<12) { _ in
						RecentCallItemView()
					}
				} header: {
					Text("Recent")
						.textCase(nil)
						.font(.headline)
						.bold()
						.foregroundStyle(Appearance.Colors.whatsAppBlack)
				}
			}
			.navigationTitle("Calls")
			.searchable(text: $store.searchText)
			.toolbar {
				leadingNavItem()
				trailingNavItem()
				principalNavItem()
			}
		}
	}
}

extension CallTabScreen {
	@ToolbarContentBuilder
	private func leadingNavItem() -> some ToolbarContent {
		ToolbarItem(placement: .topBarLeading) {
			Button("Edit") {
				
			}
		}
	}
	
	@ToolbarContentBuilder
	private func trailingNavItem() -> some ToolbarContent {
		ToolbarItem(placement: .topBarTrailing) {
			Button {
				
			} label: {
				Image(systemName: "phone.arrow.up.right")
			}
		}
	}
	
	@ToolbarContentBuilder
	private func principalNavItem() -> some ToolbarContent {
		ToolbarItem(placement: .principal) {
			Picker("", selection: $store.callHistory) {
				ForEach(CallHistory.allCases) { callHistory in
					Text(callHistory.rawValue.capitalized)
						.tag(callHistory)
				}
			}
			.pickerStyle(.segmented)
			.fixedSize()
		}
	}
}

private struct CreateCallLinkSection: View {
	var body: some View {
		HStack {
			Image(systemName: "link")
				.padding(8)
				.background(Color(.systemGray6))
				.clipShape(Circle())
				.foregroundStyle(.blue)
			VStack(alignment: .leading) {
				Text("Create Call Link")
					.foregroundStyle(.blue)
				Text("Share a link for your WhatsApp call")
					.foregroundStyle(.gray)
					.font(.caption)
			}
		}
	}
}

private struct RecentCallItemView: View {
	var body: some View {
		HStack {
			Circle()
				.frame(width: 44, height: 44)
			VStack(alignment: .leading) {
				Text("John Smith")
				HStack(spacing: 5) {
					Image(systemName: "phone.arrow.up.right.fill")
					Text("Outgoing")
				}
				.font(.system(size: 14))
				.foregroundStyle(.gray)
			}
			Spacer()
			Text("Yesterday")
				.foregroundStyle(.gray)
				.font(.system(size: 16))
			Image(systemName: "info.circle")
		}
	}
}

#Preview {
	CallTabScreen(
		store: Store(
			initialState: CallTab.State(),
			reducer: { CallTab() }
		)
	)
}
