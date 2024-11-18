//
//  File.swift
//  
//
//  Created by Anderson  on 2024/9/15.
//

import Foundation
import SwiftUI
import ComposableArchitecture
import MessageModels

public struct MessageListView: UIViewControllerRepresentable {
	public let store: StoreOf<MessageListReducer>
	public init(store: StoreOf<MessageListReducer>) {
		self.store = store
	}
	public typealias UIViewControllerType = MessageListController
	public func makeUIViewController(context: Context) -> MessageListController {
		let messageListController = MessageListController(store: store)
		return messageListController
	}
	public func updateUIViewController(_ uiViewController: MessageListController, context: Context) {
//		uiViewController.updateState(with: store.state)
	}
}
