// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Models",
	platforms: [
		.iOS(.v17),
		.macOS(.v14),
	],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "MessageModels",
			targets: ["MessageModels"]),
		.library(
			name: "AuthModels",
			targets: ["AuthModels"]),
		.library(
			name: "Constant",
			targets: ["Constant"]),
		.library(
			name: "UserModels",
			targets: ["UserModels"]),
		.library(
			name: "ChannelModels",
			targets: ["ChannelModels"]),
		.library(
			name: "MediaAttachment",
			targets: ["MediaAttachment"]),
		.library(
			name: "FirebaseFileUpload",
			targets: ["FirebaseFileUpload"]),
	],
	dependencies: [
		.package(url: "https://github.com/pointfreeco/swift-tagged.git", from: "0.10.0"),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.target(
			name: "MessageModels",
			dependencies: [
				.product(name: "Tagged", package: "swift-tagged")
			]
		),
		.target(
			name: "AuthModels",
			dependencies: [
			]
		),
		.target(
			name: "Constant",
			dependencies: [
			]
		),
		.target(
			name: "UserModels",
			dependencies: [
			]
		),
		.target(
			name: "ChannelModels",
			dependencies: [
				"UserModels",
				.product(name: "Tagged", package: "swift-tagged")
			]
		),
		.target(
			name: "MediaAttachment"
		),
		.target(
			name: "FirebaseFileUpload",
			dependencies: [
				"MediaAttachment"
			]
		),
	]
)
