// swift-tools-version:5.1
import PackageDescription

let package = Package(
	name: "ExampleMac",
	platforms: [
		.macOS(.v10_12)
	],
	products: [
    .executable(
      name: "examplemac",
      targets: [
        "Example"
      ]
    )
  ],
	dependencies: [
		.package(path: "..")
	],
	targets: [
		.target(
			name: "Example",
			dependencies: [
			  "Aperture"
			]
		)
	]
)
