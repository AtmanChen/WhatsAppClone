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
public struct CommunityTab {
	public init() {}
	@ObservableState
	public struct State: Equatable {
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

public struct CommunityTabScreen: View {
	let store: StoreOf<CommunityTab>
	public init(store: StoreOf<CommunityTab>) {
		self.store = store
	}
	public var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 10) {
					Appearance.Images.communities
					Group {
						Text("Stay connected with a community")
							.font(.title2)
						Text("Communities bring members together in topic-based groups. Any community you've added to will appear here")
							.foregroundStyle(.gray)
					}
					
					Button("See example communities >") {
						
					}
					.padding(.horizontal, 5)
					.frame(maxWidth: .infinity, alignment: .center)
					
					Button {
						
					} label: {
						Label(
							title: { Text("New Community") },
							icon: { Image(systemName: "plus") }
						)
						.bold()
					}
					.frame(maxWidth: .infinity, alignment: .center)
					.foregroundStyle(.white)
					.padding(10)
					.background(.blue)
					.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
					.padding()
				}
				.padding()
				
			}
			.navigationTitle("Communities")
		}
	}
}

#Preview {
	CommunityTabScreen(
		store: Store(
			initialState: CommunityTab.State(),
			reducer: { CommunityTab() }
		)
	)
}
