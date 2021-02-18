// swift-tools-version:5.3
import PackageDescription

let package = Package(
	name: "Aperture",
	platforms: [
		.macOS(.v11)
	],
	products: [
		.library(
			name: "Aperture",
			targets: [
				"Aperture"
			]
		)
	],
	targets: [
		.target(
			name: "Aperture"
		)
	]
)
