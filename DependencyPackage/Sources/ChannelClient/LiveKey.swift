import ChannelModels
import DatabaseClient
import Dependencies
import FirebaseAuthClient
import FirebaseDatabase
import UserModels
import FirebaseUserInfoClient
import MessageModels
import FirebaseFileUploaderClient
import FirebaseFileUpload

extension ChannelClient: DependencyKey {
	public static var liveValue = ChannelClient(
		createChannel: { channelName, partners in
			@Dependency(\.firebaseAuthClient.currentUser) var currentUser
			@Dependency(\.userInfoClient.getUser) var getUser
			@Dependency(\.databaseClient) var databaseClient
			guard let channelId = databaseClient.channelsRef().childByAutoId().key else {
				throw ChannelError.failedToGenerateChannelId
			}
			guard let currentUid = currentUser()?.uid, let currentUser = try await getUser(currentUid) else {
				throw ChannelError.currentUserNotFound
			}
			guard let channelCreatedMessageId = databaseClient.messagesRef().childByAutoId().key else {
				throw ChannelError.failedToGenerateChannelCreatedMessageId
			}
			if partners.count == 1,
				 let partner = partners.first,
				 let snapshotValue = try await databaseClient.userDirectChannelsRef().child(currentUid).child(partner.uid).getData().value as? [String: Bool],
				 let channelId = snapshotValue.keys.first {
				let channelDict = try await databaseClient.channelsRef().child(channelId).getData().value as! [String: Any]
				var channel = ChannelItem(from: channelDict)
				return channel
			}
			@Dependency(\.date.now) var now
			let timestamp = now.timeIntervalSince1970
			let members = [currentUser] + partners
			let memberUids = members.map { $0.uid }
			let channelCreatedMessage = AdminMessageType.channelCreation.rawValue
			var channelDict: [String: Any] = [
				"id": channelId,
				.channelLastMessageKey: channelCreatedMessage,
				.channelCreationDateKey: timestamp,
				"lastMessageType": channelCreatedMessage,
				.channelLastMessageTimestampKey: timestamp,
				.channelMemberUidsKey: memberUids,
				.channelMembersCountKey: UInt(memberUids.count),
				.channelAdminUidsKey: [currentUid],
				.channelCreatedByKey: currentUid,
				.channelMembersKey: members.map { $0.toDictionary() }
			]
			if let channelName, !channelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
				channelDict[.channelNameKey] = channelName
			}
			var messageDict: [String: Any] = [
				"type": channelCreatedMessage,
				"timestamp": timestamp,
				"ownerUid": currentUid
			]
			if let senderData = try? JSONEncoder().encode(currentUser),
				 let senderJSON = String(data: senderData, encoding: .utf8) {
				messageDict["sender"] = senderJSON
			}
			try await databaseClient.channelsRef().child(channelId).setValue(channelDict)
			try await databaseClient.messagesRef().child(channelId).child(channelCreatedMessageId).setValue(messageDict)
			for memberUid in memberUids {
				try await databaseClient.userChannelsRef().child(memberUid).child(channelId).setValue(true)
			}
			if partners.count == 1,
			   let partner = partners.first
			{
				try await databaseClient.userDirectChannelsRef().child(currentUid).child(partner.uid).setValue([channelId: true])
				try await databaseClient.userDirectChannelsRef().child(partner.uid).child(currentUid).setValue([channelId: true])
			}
			var channel = ChannelItem(from: channelDict)
			channel.members = members
			channel.name = channelName
			return channel
		},
		addChannelInfoListener: { channelId in
			@Dependency(\.databaseClient.channelsRef) var channelsRef
			return AsyncThrowingStream { [channelId] continuation in
				let channelRef = channelsRef().child(channelId)
				let handle = channelRef.observe(.value, with: { snapshot in
					if let channelDict = snapshot.value as? [String: Any] {
						continuation.yield(ChannelItem(from: channelDict))
					}
				})
				continuation.onTermination = { _ in
					channelRef.removeObserver(withHandle: handle)
				}
			}
		},
		addCurrentUserChannelsListener: {
			AsyncStream { continuation in
				@Dependency(\.firebaseAuthClient.currentUser) var currentUser
				guard let currentUser = currentUser() else {
					continuation.finish()
					return
				}
				@Dependency(\.databaseClient) var databaseClient
				let userChannelsRef = databaseClient.userChannelsRef()
				let currentUserChannelsRef = userChannelsRef.child(currentUser.uid)
				let handle = currentUserChannelsRef.observe(.value, with: { snapshot in
					Task {
						if let dict = snapshot.value as? [String: Any] {
							var channels: [ChannelItem] = []
							for (key, value) in dict {
								let channelId = key
								if let channelDict = try await databaseClient.channelsRef().child(channelId).getData().value as? [String: Any] {
									let channelItem = ChannelItem(from: channelDict)
									channels.append(channelItem)
								}
							}
							continuation.yield(channels.sorted(by: { $0.lastMessageTimestamp < $1.lastMessageTimestamp }))
						}
					}
				})
				continuation.onTermination = { _ in
					currentUserChannelsRef.removeObserver(withHandle: handle)
				}
			}
		},
		sendTextMessageToChannel: { channelItem, fromUser, textMessage in
			@Dependency(\.date.now) var now
			@Dependency(\.firebaseAuthClient.currentUser) var currentUser
			@Dependency(\.userInfoClient.getUser) var getUser
			let channelDict: [String: Any] = [
				"lastMessage": textMessage,
				"lastMessageTimestamp": now.timeIntervalSince1970,
				"lastMessageType": MessageType.text.title
			]
			var messageDict: [String: Any] = [
				"text": textMessage,
				"type": MessageType.text.title,
				"timestamp": now.timeIntervalSince1970,
				"ownerUid": fromUser.uid
			]
			guard let currentUid = currentUser()?.uid, let currentUser = try await getUser(currentUid) else {
				throw ChannelError.currentUserNotFound
			}
			if let senderData = try? JSONEncoder().encode(currentUser),
				 let senderJSON = String(data: senderData, encoding: .utf8) {
				messageDict["sender"] = senderJSON
			}
			@Dependency(\.databaseClient) var databaseClient
			let channelsRef = databaseClient.channelsRef()
			let messagesRef = databaseClient.messagesRef()
			guard let messageId = messagesRef.childByAutoId().key else {
				return
			}
			try await channelsRef.child(channelItem.id).updateChildValues(channelDict)
			try await messagesRef.child(channelItem.id).child(messageId).setValue(messageDict)
		},
		sendAttachmentsMessageToChannel: { messageParams in
			@Dependency(\.uploader) var uploader
			@Dependency(\.firebaseAuthClient.currentUser) var currentUser
			@Dependency(\.userInfoClient.getUser) var getUser
			guard let currentUid = currentUser()?.uid, let currentUser = try await getUser(currentUid) else {
				throw ChannelError.currentUserNotFound
			}
			let uploadContent: UploadFileType
			switch messageParams.attachment {
			case let .image(id, thumbnail):
				uploadContent = .photoMessage(fileId: id, image: thumbnail)
			case let .video(id, thumbnail, url):
				uploadContent = .videoMessage(fileId: id, thumbnail: thumbnail, fileURL: url)
			case let .audio(url, duration):
				uploadContent = .audioMessage(fileId: url.absoluteString, fileURL: url, duration: duration)
			}
			for try await uploadResult in uploader.uploadContent(uploadContent) {
				if case let .completion(fileId, thumbnailUrl, url) = uploadResult {
					@Dependency(\.date.now) var now
					@Dependency(\.databaseClient) var databaseClient
					let channelsRef = databaseClient.channelsRef()
					let messagesRef = databaseClient.messagesRef()
					guard let messageId = messagesRef.childByAutoId().key else {
						return
					}
					let channelDict: [String: Any] = [
						"lastMessage": messageParams.text,
						"lastMessageTimestamp": now.timeIntervalSince1970,
						"lastMessageType": messageParams.type.title,
					]
					var messageDict: [String: Any] = [
						"text": messageParams.text,
						"type": messageParams.type.title,
						"timestamp": now.timeIntervalSince1970,
						"ownerUid": messageParams.sender.uid,
						"thumbnailUrl": messageParams.type == .photo ? url.absoluteString : thumbnailUrl?.absoluteString ?? "",
						"audioDuration": messageParams.audioDuration ?? 0,
						"audioUrl": messageParams.type == .audio ? url.absoluteString : "",
						"videoUrl": messageParams.type == .video ? url.absoluteString : ""
					]
					
					if let senderData = try? JSONEncoder().encode(currentUser),
						 let senderJSON = String(data: senderData, encoding: .utf8) {
						messageDict["sender"] = senderJSON
					}
					messageDict["thumbnailWidth"] = messageParams.thumbnailWidth ?? nil
					messageDict["thumbnailHeight"] = messageParams.thumbnailHeight ?? nil
					debugPrint(messageDict)
					try await channelsRef.child(messageParams.channel.id).updateChildValues(channelDict)
					try await messagesRef.child(messageParams.channel.id).child(messageId).setValue(messageDict)
				}
			}
		},
		getMessagesOfChannel: { channelId in
			AsyncStream { continuation in
				@Dependency(\.databaseClient) var databaseClient
				let messagesRef = databaseClient.messagesRef()
				let handle = messagesRef.child(channelId).queryOrdered(byChild: "timestamp").observe(.childAdded, with: { snapshot in
					guard let dict = snapshot.value as? [String: Any] else {
						return
					}
					@Dependency(\.firebaseAuthClient.currentUser) var currentUser
					let message = MessageItem(id: snapshot.key, currentUid: currentUser()!.uid, dict: dict)
					continuation.yield(message)
				})
				continuation.onTermination = { [weak messagesRef] _ in
					messagesRef?.removeObserver(withHandle: handle)
				}
			}
		}
	)
}
