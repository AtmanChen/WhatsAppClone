// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "WhatsAppFeatures",
	platforms: [
		.iOS(.v17),
		.macOS(.v14)
	],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "AppFeature",
			targets: ["AppFeature"]
		),
		.library(
			name: "MainTabFeature",
			targets: ["MainTabFeature"]
		),
		.library(
			name: "UpdateTabScreenFeature",
			targets: ["UpdateTabScreenFeature"]
		),
		.library(
			name: "CallTabScreenFeature",
			targets: ["CallTabScreenFeature"]
		),
		.library(
			name: "CommunityTabScreenFeature",
			targets: ["CommunityTabScreenFeature"]
		),
		.library(
			name: "ChatTabScreenFeature",
			targets: ["ChatTabScreenFeature"]
		),
		.library(
			name: "SettingsTabScreenFeature",
			targets: ["SettingsTabScreenFeature"]
		),
		.library(
			name: "ChatRoomFeature",
			targets: ["ChatRoomFeature"]
		),
		.library(
			name: "AuthFeature",
			targets: ["AuthFeature"]
		),
		.library(
			name: "LaunchFeature",
			targets: ["LaunchFeature"]
		),
		.library(
			name: "ChatPartnerScreenFeature",
			targets: ["ChatPartnerScreenFeature"]
		),
		.library(
			name: "MediaAttachmentPreviewFeature",
			targets: ["MediaAttachmentPreviewFeature"]
		),
		.library(
			name: "AudioPlayerFeature",
			targets: ["AudioPlayerFeature"]
		)
	],
	dependencies: [
		.package(path: "../Models"),
		.package(path: "../UIComponentsPackage"),
		.package(path: "../DependencyPackage"),
		.package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.14.0"),
		.package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.10.0")
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "AppFeature",
			dependencies: [
				"MainTabFeature",
				"AuthFeature",
				"LaunchFeature",
				.product(name: "Effect+Extensions", package: "DependencyPackage"),
				.product(name: "Constant", package: "Models"),
				.product(name: "NotificationCenterClient", package: "DependencyPackage"),
				.product(name: "AuthModels", package: "Models"),
				.product(name: "FirebaseCoreClient", package: "DependencyPackage"),
				.product(name: "TCAHelpers", package: "DependencyPackage"),
				.product(name: "Appearance", package: "UIComponentsPackage"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			]
		),
		.target(
			name: "MainTabFeature",
			dependencies: [
				"UpdateTabScreenFeature",
				"CallTabScreenFeature",
				"CommunityTabScreenFeature",
				"ChatTabScreenFeature",
				"SettingsTabScreenFeature",
				.product(name: "Appearance", package: "UIComponentsPackage"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			]
		),
		.target(
			name: "UpdateTabScreenFeature",
			dependencies: [
				.product(name: "Appearance", package: "UIComponentsPackage"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			]
		),
		.target(
			name: "CallTabScreenFeature",
			dependencies: [
				.product(name: "Appearance", package: "UIComponentsPackage"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			]
		),
		.target(
			name: "CommunityTabScreenFeature",
			dependencies: [
				.product(name: "Appearance", package: "UIComponentsPackage"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			]
		),
		.target(
			name: "ChatTabScreenFeature",
			dependencies: [
				"ChatRoomFeature",
				"ChatPartnerScreenFeature",
				.product(name: "UserUIComponents", package: "UIComponentsPackage"),
				.product(name: "Effect+Extensions", package: "DependencyPackage"),
				.product(name: "ChannelClient", package: "DependencyPackage"),
				.product(name: "DateFormattClient", package: "DependencyPackage"),
				.product(name: "AuthModels", package: "Models"),
				.product(name: "UserModels", package: "Models"),
				.product(name: "ChannelModels", package: "Models"),
				.product(name: "Appearance", package: "UIComponentsPackage"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			]
		),
		.target(
			name: "SettingsTabScreenFeature",
			dependencies: [
				.product(name: "Effect+Extensions", package: "DependencyPackage"),
				.product(name: "Constant", package: "Models"),
				.product(name: "NotificationCenterClient", package: "DependencyPackage"),
				.product(name: "Toast", package: "UIComponentsPackage"),
				.product(name: "FirebaseAuthClient", package: "DependencyPackage"),
				.product(name: "Appearance", package: "UIComponentsPackage"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			]
		),
		.target(
			name: "ChatRoomFeature",
			dependencies: [
				"MediaAttachmentPreviewFeature",
				"AudioPlayerFeature",
				.product(name: "MediaAttachment", package: "Models"),
				.product(name: "PhotosClient", package: "DependencyPackage"),
				.product(name: "DateFormattClient", package: "DependencyPackage"),
				.product(name: "UserUIComponents", package: "UIComponentsPackage"),
				.product(name: "MediaPlayerView", package: "UIComponentsPackage"),
				.product(name: "Effect+Extensions", package: "DependencyPackage"),
				.product(name: "ChannelClient", package: "DependencyPackage"),
				.product(name: "AudioRecorderClient", package: "DependencyPackage"),
				.product(name: "MessageModels", package: "Models"),
				.product(name: "UserModels", package: "Models"),
				.product(name: "ChannelModels", package: "Models"),
				.product(name: "MessageBubble", package: "UIComponentsPackage"),
				.product(name: "Appearance", package: "UIComponentsPackage"),
				.product(name: "FirebaseAuthClient", package: "DependencyPackage"),
				.product(name: "FirebaseUserInfoClient", package: "DependencyPackage"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			]
		),
		.target(
			name: "AuthFeature",
			dependencies: [
				.product(name: "Toast", package: "UIComponentsPackage"),
				.product(name: "FirebaseAuthClient", package: "DependencyPackage"),
				.product(name: "AuthUIComponents", package: "UIComponentsPackage"),
				.product(name: "Appearance", package: "UIComponentsPackage"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			]
		),
		.target(
			name: "LaunchFeature",
			dependencies: [
				.product(name: "Appearance", package: "UIComponentsPackage"),
				.product(name: "Animations", package: "UIComponentsPackage"),
				.product(name: "AuthUIComponents", package: "UIComponentsPackage"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			]
		),
		.testTarget(
			name: "LaunchFeatureTests",
			dependencies: [
				"LaunchFeature",
				.product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			],
			exclude: ["__Snapshots__"]
		),
		.target(
			name: "ChatPartnerScreenFeature",
			dependencies: [
				.product(name: "ChannelClient", package: "DependencyPackage"),
				.product(name: "Effect+Extensions", package: "DependencyPackage"),
				.product(name: "Constant", package: "Models"),
				.product(name: "Toast", package: "UIComponentsPackage"),
				.product(name: "UserUIComponents", package: "UIComponentsPackage"),
				.product(name: "AuthModels", package: "Models"),
				.product(name: "UserModels", package: "Models"),
				.product(name: "ChannelModels", package: "Models"),
				.product(name: "Appearance", package: "UIComponentsPackage"),
				.product(name: "Animations", package: "UIComponentsPackage"),
				.product(name: "AuthUIComponents", package: "UIComponentsPackage"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			]
		),
		.target(
			name: "MediaAttachmentPreviewFeature",
			dependencies: [
				.product(name: "MediaAttachment", package: "Models"),
				.product(name: "UI+Extensions", package: "UIComponentsPackage"),
				.product(name: "CommonComponents", package: "UIComponentsPackage"),
				.product(name: "ChannelClient", package: "DependencyPackage"),
				.product(name: "Effect+Extensions", package: "DependencyPackage"),
				.product(name: "Constant", package: "Models"),
				.product(name: "Toast", package: "UIComponentsPackage"),
				.product(name: "UserUIComponents", package: "UIComponentsPackage"),
				.product(name: "AuthModels", package: "Models"),
				.product(name: "UserModels", package: "Models"),
				.product(name: "ChannelModels", package: "Models"),
				.product(name: "Appearance", package: "UIComponentsPackage"),
				.product(name: "Animations", package: "UIComponentsPackage"),
				.product(name: "AuthUIComponents", package: "UIComponentsPackage"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			]
		),
		.target(
			name: "AudioPlayerFeature",
			dependencies: [
				.product(name: "Appearance", package: "UIComponentsPackage"),
				.product(name: "AudioPlayerClient", package: "DependencyPackage"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			],
			resources: [
				.copy("Preview Content")
			]
		)
	]
)
