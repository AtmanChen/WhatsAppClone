import Appearance
import AudioRecorderClient
import ChannelModels
import ComposableArchitecture
import DateFormattClient
import FirebaseAuthClient
import FirebaseUserInfoClient
import Foundation
import MediaAttachment
import MessageBubble
import MessageModels
import SwiftUI
import UIKit
import UserModels
import UserUIComponents

extension MessageItem {
	func toUserItem() async -> UserItem? {
		@Dependency(\.userInfoClient.getUser) var getUser
		do {
			let user = try await getUser(ownerUid)
			return user
		} catch {
			return nil
		}
	}
}

@Reducer
public struct MessageListReducer {
	public init() {}
	@ObservableState
	public struct State: Equatable {
		public init(channel: ChannelItem, messages: [MessageItem]) {
			self.channel = channel
			self.messages = IdentifiedArray(uniqueElements: messages.map { MessageListItemReducer.State(message: $0) })
			@Dependency(\.firebaseAuthClient.currentUser) var currentUser
			self.currentUser = currentUser()?.uid
		}

		var channel: ChannelItem
		var messages: IdentifiedArrayOf<MessageListItemReducer.State>
		var currentUser: String?
		var audioPlayback: AudioPlayback?
		var historialMessagesRemains = false
		var isLoadingHistoricalMessages = false

		public struct AudioPlayback: Equatable {
			public var bubbleTag: String
			public var isPlaying: Bool
			public var currentTime: TimeInterval
		}
	}

	public enum Action {
		case messages(IdentifiedActionOf<MessageListItemReducer>)
		case messagesUpdated(messages: [MessageItem], fromLatest: Bool, historialMessagesRemains: Bool)
		case onTapChatBackground
		case updateAudioPlaybackCurrentTime(bubbleTag: String, updatedCurrentTime: TimeInterval)
		case toggleAudioPlayStatus(bubbleTag: String, isPlaying: Bool)
		case didFinishAudioPlayStatue(bubbleTag: String)
		case onTapAudioBubblePlayButton(bubbleTag: String, audioFilePath: String, duration: TimeInterval, isPlaying: Bool)
		case loadMoreHistoricalMessages
		case delegate(Delegate)
		public enum Delegate {
			case onTapChatBackground
			case onTapAudioPlay(bubbleTag: String, audioFilePath: String, isPlaying: Bool, audioDuration: TimeInterval)
			case updateAudioPlaybackCurrentTime(bubbleTag: String, updatedCurrentTime: TimeInterval)
			case toggleAudioPlayStatus(bubbleTag: String, audioFilePath: String, isPlaying: Bool, duration: TimeInterval)
			case loadMoreHistoricalMessages
		}
	}
	
	private enum LoadMoreHistoricalMessages {
		case ID
	}

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .messages:
				return .none
			case let .messagesUpdated(messages, fromLatest, historialMessagesRemains):
				let messageItems = messages.map { MessageListItemReducer.State(message: $0) }
				if fromLatest {
					for messageItem in messageItems {
						state.messages.insert(messageItem, at: 0)
					}
				} else {
					state.isLoadingHistoricalMessages = false
					state.messages.append(contentsOf: messageItems)
				}
				state.historialMessagesRemains = historialMessagesRemains
				return .none
			case .delegate:
				return .none
			case let .updateAudioPlaybackCurrentTime(bubbleTag, updatedCurrentTime):
				guard bubbleTag == state.audioPlayback?.bubbleTag else {
					return .none
				}
				if state.audioPlayback?.currentTime != updatedCurrentTime {
					state.audioPlayback?.currentTime = updatedCurrentTime
				}
				return .none
			case let .toggleAudioPlayStatus(bubbleTag, isPlaying):
				if state.audioPlayback?.bubbleTag != bubbleTag {
					state.audioPlayback = State.AudioPlayback(bubbleTag: bubbleTag, isPlaying: isPlaying, currentTime: 0)
				} else {
					state.audioPlayback?.isPlaying = isPlaying
				}
				return .none
			case let .didFinishAudioPlayStatue(bubbleTag):
				guard state.audioPlayback?.bubbleTag == bubbleTag else {
					return .none
				}
				state.audioPlayback = nil
				return .none
			case let .onTapAudioBubblePlayButton(bubbleTag, audioFilePath, duration, isPlaying):
				if state.audioPlayback == nil {
					state.audioPlayback = State.AudioPlayback(bubbleTag: bubbleTag, isPlaying: false, currentTime: 0)
				}
				return .send(.delegate(.toggleAudioPlayStatus(bubbleTag: bubbleTag, audioFilePath: audioFilePath, isPlaying: isPlaying, duration: duration)))
			case .onTapChatBackground:
				return .send(.delegate(.onTapChatBackground))
				
			case .loadMoreHistoricalMessages:
				debugPrint(state.isLoadingHistoricalMessages)
				if state.isLoadingHistoricalMessages {
					return .none
				}
				state.isLoadingHistoricalMessages = true
				return .send(.delegate(.loadMoreHistoricalMessages)).debounce(id: LoadMoreHistoricalMessages.ID, for: .milliseconds(500), scheduler: DispatchQueue.main)
			}
		}
		.forEach(\.messages, action: \.messages) {
			MessageListItemReducer()
		}
	}
}

@Reducer
public struct MessageListItemReducer {
	public init() {}

	@ObservableState
	public struct State: Equatable, Identifiable, Hashable, Comparable {
		var message: MessageItem
		public init(message: MessageItem) {
			self.message = message
		}

		public var id: String {
			message.id
		}

		public var messageTimestampString: String {
			@Dependency(\.dateFormattClient.timeRepresentation) var timeRepresentation
			return timeRepresentation(message.timestamp)
		}

		public static func < (lhs: MessageListItemReducer.State, rhs: MessageListItemReducer.State) -> Bool {
			return lhs.message.timestamp < rhs.message.timestamp
		}
	}

	public enum Action {
		case delegate(Delegate)

		public enum Delegate {
			case onLongTapMessage(MessageItem)
		}
	}

	public var body: some ReducerOf<Self> {
		Reduce { _, action in
			switch action {
			case .delegate:
				return .none
			}
		}
	}
}

public final class MessageListController: UIViewController {
	@Bindable public var store: StoreOf<MessageListReducer>
	private var isApplyingSnapshot = false
//	public var dataSource: UITableViewDiffableDataSource<MessageListController.MessageListSection, MessageListItemReducer.State>!
	public var dataSource: UICollectionViewDiffableDataSource<MessageListController.MessageListSection, MessageListItemReducer.State>!
	private let layout = UICollectionViewCompositionalLayout { _, layoutEnvironment in
		var config = UICollectionLayoutListConfiguration(appearance: .plain)
		config.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
		config.showsSeparators = false
		let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
		section.contentInsets.leading = 0
		section.contentInsets.trailing = 0
		section.interGroupSpacing = -10
		let footerSize = NSCollectionLayoutSize(
			widthDimension: .fractionalWidth(1.0),
			heightDimension: .absolute(50)
		)
		let footer = NSCollectionLayoutBoundarySupplementaryItem(
			layoutSize: footerSize,
			elementKind: UICollectionView.elementKindSectionFooter,
			alignment: .bottom
		)
		section.boundarySupplementaryItems = [footer]
		return section
	}

	public init(store: StoreOf<MessageListReducer>) {
		self.store = store
		super.init(nibName: nil, bundle: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private lazy var messagesCollectionView: UICollectionView = {
		let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
		collectionView.translatesAutoresizingMaskIntoConstraints = false
		collectionView.delegate = self
		collectionView.selfSizingInvalidation = .enabledIncludingConstraints
		collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
		collectionView.keyboardDismissMode = .onDrag
		collectionView.backgroundColor = .clear
		collectionView.transform = CGAffineTransform(scaleX: 1, y: -1)
		collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
		collectionView.register(
			LoadingReusableView.self,
			forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
			withReuseIdentifier: LoadingReusableView.reuseIdentifier
		)
		return collectionView
	}()

	override public func viewDidLoad() {
		super.viewDidLoad()
		setupView()
		setupDatasource()
		observe { [weak self] in
			guard let self else { return }
			self.updateSnapshot(with: store.messages)
			if let footer = self.messagesCollectionView.supplementaryView(
				forElementKind: UICollectionView.elementKindSectionFooter,
				at: IndexPath(item: 0, section: 0)
			) as? LoadingReusableView {
				if self.store.isLoadingHistoricalMessages {
					footer.startAnimating()
				} else {
					footer.stopAnimating()
				}
			}
		}
	}

	private let cellIdentifier = "MessageListControllerCell"
	private func setupDatasource() {
		dataSource = UICollectionViewDiffableDataSource<MessageListSection, MessageListItemReducer.State>(collectionView: messagesCollectionView) {
			[weak self] collectionView,
				indexPath,
				_ in
			guard let self else { return UICollectionViewCell() }
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
			cell.backgroundColor = .clear
			let messageState = store.messages[indexPath.item]
			let message = messageState.message
			let contentWidth = collectionView.bounds.width
			cell.contentConfiguration = UIHostingConfiguration { [weak self, message, store] in
				MessageBubbleView(
					message: message,
					channel: store.channel,
					contentWidth: contentWidth,
					currentUserId: store.currentUser ?? "",
					isNewDay: self?.isNewday(of: message, at: indexPath.item) ?? false,
					showSender: self?.showSender(of: message, at: indexPath.item) ?? false,
					audioPlayCurrentTime: Binding(
						get: {
							guard store.audioPlayback?.bubbleTag == message.id else { return 0 }
							return store.audioPlayback?.currentTime ?? 0
						},
						set: { newValue in
							store.send(.delegate(.updateAudioPlaybackCurrentTime(bubbleTag: message.id, updatedCurrentTime: newValue)))
						}
					),
					audioPlayPlaying: Binding<Bool>(
						get: {
							guard store.audioPlayback?.bubbleTag == message.id else { return false }
							return store.audioPlayback?.isPlaying ?? false
						},
						set: { newValue in
							store.send(
								.onTapAudioBubblePlayButton(bubbleTag: message.id, audioFilePath: message.audioUrl ?? "", duration: message.audioDuration ?? 0, isPlaying: newValue)
							)
						}
					)
				)
				.scaleEffect(x: 1, y: -1)
			}
			return cell
		}
		dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
			guard kind == UICollectionView.elementKindSectionFooter else { return nil }
//			guard let self else { return nil }
			let footer = collectionView.dequeueReusableSupplementaryView(
				ofKind: kind,
				withReuseIdentifier: LoadingReusableView.reuseIdentifier,
				for: indexPath
			) as! LoadingReusableView
			footer.transform = CGAffineTransform(scaleX: 1, y: -1)
			return footer
		}
	}

	private func setupView() {
		view.backgroundColor = .clear
		let chatBackgroundImageView = UIImageView(image: Appearance.Images.chatBackground)
		chatBackgroundImageView.translatesAutoresizingMaskIntoConstraints = false
		chatBackgroundImageView.contentMode = .scaleToFill
		view.addSubview(chatBackgroundImageView)
		view.addSubview(messagesCollectionView)
		NSLayoutConstraint.activate([
			chatBackgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
			chatBackgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			chatBackgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			chatBackgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			messagesCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
			messagesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			messagesCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			messagesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
		])
	}

	public func updateState(with state: MessageListReducer.State) {
		updateSnapshot(with: state.messages)
	}

	private func updateSnapshot(with messages: IdentifiedArrayOf<MessageListItemReducer.State>) {
		var snapshot = NSDiffableDataSourceSnapshot<MessageListSection, MessageListItemReducer.State>()
		snapshot.appendSections([.main])
		snapshot.appendItems(messages.elements, toSection: .main)
		isApplyingSnapshot = true
		dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
			guard let self else { return }
			isApplyingSnapshot = false
		}
	}
}

private extension UICollectionView {
	func scrollToLastRow(at scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
		guard numberOfItems(inSection: numberOfSections - 1) > 0 else {
			return
		}
		let lastSectionIndex = numberOfSections - 1
		let lastRowIndex = 0
		let lastRowIndexPath = IndexPath(row: lastRowIndex, section: lastSectionIndex)
		scrollToItem(at: lastRowIndexPath, at: scrollPosition, animated: animated)
	}
}

public extension MessageListController {
	func isNewday(of message: MessageItem, at index: Int) -> Bool {
		let priorIndex = min(store.messages.count - 1, index + 1)
		let priorMessage = store.messages[priorIndex].message
		return !Calendar.current.isDate(message.timestamp, inSameDayAs: priorMessage.timestamp)
	}

	func showSender(of message: MessageItem, at index: Int) -> Bool {
		let priorIndex = min(store.messages.count - 1, index + 1)
		let priorMessage = store.messages[priorIndex].message
		return store.channel.isGroupChat && (message.sender.uid != store.currentUser) && (message.sender.uid != priorMessage.sender.uid || (priorMessage.type.title == "admin" && message.type.title != "admin"))
	}

	enum MessageListSection {
		case main
	}
	private func loadMoreMessages() {
		store.send(.loadMoreHistoricalMessages)
	}
}

extension MessageListController: UICollectionViewDelegate {
	public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		store.send(.onTapChatBackground)
	}

	public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		guard !isApplyingSnapshot else { return }
		guard store.historialMessagesRemains else { return }
		guard store.isLoadingHistoricalMessages == false else { return }
		let position = scrollView.contentOffset.y
		let contentHeight = scrollView.contentSize.height
		let scrollViewHeight = scrollView.bounds.size.height

		// 当滚动到底部时加载更多
		if position > contentHeight - scrollViewHeight - 100 {
			loadMoreMessages()
		}
	}
}

extension MessageItem {}

class LoadingReusableView: UICollectionReusableView {
	static let reuseIdentifier = "LoadingReusableView"

	private let activityIndicator: UIActivityIndicatorView = {
		let indicator = UIActivityIndicatorView(style: .medium)
		indicator.hidesWhenStopped = true
		indicator.translatesAutoresizingMaskIntoConstraints = false
		return indicator
	}()

	override init(frame: CGRect) {
		super.init(frame: frame)
		setupViews()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupViews() {
		addSubview(activityIndicator)
		NSLayoutConstraint.activate([
			activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
			activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
		])
	}

	func startAnimating() {
		activityIndicator.startAnimating()
	}

	func stopAnimating() {
		activityIndicator.stopAnimating()
	}
}
