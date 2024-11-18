// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "UIComponentsPackage",
	platforms: [
		.iOS(.v17),
		.macOS(.v14),
	],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "Appearance",
			targets: ["Appearance"]
		),
		.library(
			name: "MessageBubble",
			targets: ["MessageBubble"]
		),
		.library(
			name: "AuthUIComponents",
			targets: ["AuthUIComponents"]
		),
		.library(
			name: "Animations",
			targets: ["Animations"]
		),
		.library(
			name: "Toast",
			targets: ["Toast"]
		),
		.library(
			name: "UserUIComponents",
			targets: ["UserUIComponents"]
		),
		.library(
			name: "CommonComponents",
			targets: ["CommonComponents"]
		),
		.library(
			name: "UI+Extensions",
			targets: ["UI+Extensions"]
		),
		.library(
			name: "MediaPlayerView",
			targets: ["MediaPlayerView"]
		),
	],
	dependencies: [
		.package(path: "../Models"),
		.package(path: "../DependencyPackage"),
		.package(url: "https://github.com/mac-cain13/R.swift.git", from: "7.5.0"),
		.package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.14.0"),
		.package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMajor(from: "7.0.0")),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "Appearance",
			dependencies: [
				.product(name: "RswiftLibrary", package: "R.swift"),
			],
			resources: [
				.process("Resources/Assets.xcassets"),
			],
			plugins: [
				.plugin(name: "RswiftGeneratePublicResources", package: "R.swift"),
			]
		),
		.target(
			name: "MessageBubble",
			dependencies: [
				"Appearance",
				"UserUIComponents",
				"MediaPlayerView",
				"UI+Extensions",
				.product(name: "DateFormattClient", package: "DependencyPackage"),
				.product(name: "FirebaseUserInfoClient", package: "DependencyPackage"),
				.product(name: "MessageModels", package: "Models"),
				.product(name: "ChannelModels", package: "Models"),
				.product(name: "UserModels", package: "Models"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
				.product(name: "Kingfisher", package: "Kingfisher"),
			]
		),
		.target(
			name: "AuthUIComponents",
			dependencies: [
				"Appearance",
			]
		),
		.target(
			name: "Animations"
		),
		.target(
			name: "Toast"
		),
		.target(
			name: "UserUIComponents",
			dependencies: [
				"Appearance",
				.product(name: "UserModels", package: "Models"),
				.product(name: "ChannelModels", package: "Models"),
				.product(name: "Effect+Extensions", package: "DependencyPackage"),
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
				.product(name: "Kingfisher", package: "Kingfisher"),
			]
		),
		.target(
			name: "CommonComponents",
			dependencies: [
				"Appearance"
			]
		),
		.target(
			name: "UI+Extensions",
			dependencies: [
				"Appearance",
				.product(name: "MediaAttachment", package: "Models")
			]
		),
		.target(
			name: "MediaPlayerView",
			dependencies: [
				"Appearance",
				"CommonComponents",
			]
		),
	]
)
