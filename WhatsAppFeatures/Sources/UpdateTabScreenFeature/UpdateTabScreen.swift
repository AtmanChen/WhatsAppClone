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

@Reducer
public struct UpdateTab {
	public init() {}
	@ObservableState
	public struct State: Equatable {
		var searchText = ""
		public init() {}
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

public struct UpdateTabScreen: View {
	@Bindable var store: StoreOf<UpdateTab>
	public init(store: StoreOf<UpdateTab>) {
		self.store = store
	}
	public var body: some View {
		NavigationStack {
			List {
				StatusSectionHeader()
					.listRowBackground(Color.clear)
				StatusSection()
				Section {
					RecentUpdatesItemView()
				} header: {
					Text("RECENT UPDATES")
				}
				Section {
					ChannelListView()
				} header: {
					HStack {
						Text("Channels")
							.font(.title3)
							.bold()
							.textCase(nil)
						Spacer()
						Button {
							
						} label: {
							Image(systemName: "plus")
								.padding(5)
								.background(Color(.systemGray5))
								.clipShape(Circle())
						}
					}
				}
			}
			.listStyle(.grouped)
			.navigationTitle("Updates")
			.searchable(text: $store.searchText)
		}
	}
}

private struct StatusSectionHeader: View {
	var body: some View {
		HStack(alignment: .top) {
			Image(systemName: "circle.dashed")
				.foregroundStyle(.blue)
				.imageScale(.large)
			(
				Text("Use Status to share photos, text and videos that disappear in 24 hours.")
				+
				Text("\n")
				+
				Text("Status Privacy")
					.foregroundStyle(.blue)
					.bold()
			)
			Image(systemName: "xmark")
				.foregroundStyle(.gray)
		}
		.padding()
		.background(Appearance.Colors.whatsAppWhite)
		.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
	}
}

private struct StatusSection: View {
	var body: some View {
		HStack {
			Circle()
				.frame(width: 44, height: 44)
			VStack(alignment: .leading) {
				Text("My Status")
					.font(.callout)
					.bold()
				Text("Add to my status")
					.foregroundStyle(.gray)
					.font(.system(size: 15))
			}
			Spacer()
			cameraButton()
			pencilButton()
		}
	}
	private func cameraButton() -> some View {
		Button {
			
		} label: {
			Image(systemName: "camera.fill")
				.padding(10)
				.background(Color(.systemGray5))
				.clipShape(Circle())
				.bold()
		}
	}
	
	private func pencilButton() -> some View {
		Button {
			
		} label: {
			Image(systemName: "pencil")
				.padding(10)
				.background(Color(.systemGray5))
				.clipShape(Circle())
				.bold()
		}
	}
}

private struct RecentUpdatesItemView: View {
	var body: some View {
		HStack {
			Circle()
				.frame(width: 44, height: 44)
			VStack(alignment: .leading) {
				Text("Joseph Smith")
					.font(.callout)
					.bold()
				Text("1hr ago")
					.foregroundStyle(.gray)
					.font(.system(size: 15))
			}
		}
	}
}

private struct ChannelListView: View {
	var body: some View {
		VStack(alignment: .leading) {
			Text("Stay updated on topics that matter to you. Find channels to follow below.")
				.foregroundStyle(.gray)
				.font(.callout)
				.padding(.horizontal)
			ScrollView(.horizontal, showsIndicators: false) {
				HStack {
					ForEach(0..<5) { _ in
						ChannelItemView()
					}
				}
			}
			Button("Explore More") {
				
			}
			.tint(.blue)
			.bold()
			.buttonStyle(.borderedProminent)
			.clipShape(Capsule())
			.padding(.vertical)
		}
	}
}

private struct ChannelItemView: View {
	var body: some View {
		VStack {
			Circle()
				.frame(width: 35, height: 35)
			Text("Real Madrid C.F")
			Button {
				
			} label: {
				Text("Follow")
					.bold()
					.padding(5)
					.frame(maxWidth: .infinity)
					.background(Color.blue.opacity(0.2))
					.clipShape(Capsule())
			}
		}
		.padding(.horizontal, 16)
		.padding(.vertical)
		.overlay(
			RoundedRectangle(cornerRadius: 10)
				.stroke(Color(.systemGray4), lineWidth: 1)
		)
	}
}

#Preview {
	UpdateTabScreen(
		store: Store(
			initialState: UpdateTab.State(),
			reducer: { UpdateTab() }
		)
	)
}
