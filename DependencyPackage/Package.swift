// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "DependencyPackage",
	platforms: [
		.iOS(.v17),
		.macOS(.v14),
	],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "FirebaseCoreClient",
			targets: ["FirebaseCoreClient"]),
		.library(
			name: "FirebaseAuthClient",
			targets: ["FirebaseAuthClient"]),
		.library(
			name: "TCAHelpers",
			targets: ["TCAHelpers"]),
		.library(
			name: "NotificationCenterClient",
			targets: ["NotificationCenterClient"]),
		.library(
			name: "Effect+Extensions",
			targets: ["Effect+Extensions"]),
		.library(
			name: "FirebaseUserInfoClient",
			targets: ["FirebaseUserInfoClient"]),
		.library(
			name: "DatabaseClient",
			targets: ["DatabaseClient"]),
		.library(
			name: "FirebaseUsersClient",
			targets: ["FirebaseUsersClient"]),
		.library(
			name: "ChannelClient",
			targets: ["ChannelClient"]),
		.library(
			name: "DateFormattClient",
			targets: ["DateFormattClient"]),
		.library(
			name: "PhotosClient",
			targets: ["PhotosClient"]),
		.library(
			name: "AudioRecorderClient",
			targets: ["AudioRecorderClient"]),
		.library(
			name: "FirebaseFileUploaderClient",
			targets: ["FirebaseFileUploaderClient"]),
		.library(
			name: "StorageClient",
			targets: ["StorageClient"]),
		.library(
			name: "HapticsClient",
			targets: ["HapticsClient"]),
		.library(
			name: "AudioPlayerClient",
			targets: ["AudioPlayerClient"]),
	],
	dependencies: [
		.package(path: "../Models"),
		.package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.0.0"),
		.package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "10.4.0")),
		.package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.14.0"),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "FirebaseCoreClient",
			dependencies: [
				.product(name: "FirebaseInstallations", package: "firebase-ios-sdk"),
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
			]
		),
		.target(
			name: "FirebaseAuthClient",
			dependencies: [
				"DatabaseClient",
				.product(name: "AuthModels", package: "Models"),
				.product(name: "UserModels", package: "Models"),
				.product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
			]
		),
		.target(
			name: "TCAHelpers",
			dependencies: [
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
			]
		),
		.target(
			name: "NotificationCenterClient",
			dependencies: [
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
			]
		),
		.target(
			name: "Effect+Extensions",
			dependencies: [
				"FirebaseAuthClient",
				"FirebaseUserInfoClient",
				"NotificationCenterClient",
				"FirebaseUsersClient",
				"ChannelClient",
				.product(name: "AuthModels", package: "Models"),
				.product(name: "UserModels", package: "Models"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
			]
		),
		.target(
			name: "FirebaseUserInfoClient",
			dependencies: [
				"DatabaseClient",
				.product(name: "UserModels", package: "Models"),
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
			]
		),
		.target(
			name: "DatabaseClient",
			dependencies: [
				.product(name: "AuthModels", package: "Models"),
				.product(name: "FirebaseDatabase", package: "firebase-ios-sdk"),
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
			]
		),
		.target(
			name: "FirebaseUsersClient",
			dependencies: [
				"DatabaseClient",
				"FirebaseAuthClient",
				.product(name: "UserModels", package: "Models"),
				.product(name: "FirebaseDatabase", package: "firebase-ios-sdk"),
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
			]
		),
		.target(
			name: "ChannelClient",
			dependencies: [
				"DatabaseClient",
				"FirebaseAuthClient",
				"FirebaseUserInfoClient",
				"FirebaseFileUploaderClient",
				.product(name: "MediaAttachment", package: "Models"),
				.product(name: "ChannelModels", package: "Models"),
				.product(name: "UserModels", package: "Models"),
				.product(name: "MessageModels", package: "Models"),
				.product(name: "FirebaseDatabase", package: "firebase-ios-sdk"),
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "FirebaseFileUpload", package: "Models"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
				.product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
			]
		),
		.target(
			name: "DateFormattClient",
			dependencies: [
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
			]
		),
		.target(
			name: "PhotosClient",
			dependencies: [
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
			]
		),
		.target(
			name: "AudioRecorderClient",
			dependencies: [
				"DateFormattClient",
				"HapticsClient",
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture")
			]
		),
		.target(
			name: "FirebaseFileUploaderClient",
			dependencies: [
				"StorageClient",
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
				.product(name: "FirebaseFileUpload", package: "Models"),
				.product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
			]
		),
		.target(
			name: "StorageClient",
			dependencies: [
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
				.product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
			]
		),
		.target(
			name: "HapticsClient",
			dependencies: [
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
			]
		),
		.target(
			name: "AudioPlayerClient",
			dependencies: [
				.product(name: "Dependencies", package: "swift-dependencies"),
				.product(name: "DependenciesMacros", package: "swift-dependencies"),
			]
		),
	])
