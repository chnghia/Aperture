// swift-tools-version:5.3
import PackageDescription

let package = Package(
	name: "ExampleMac",
	platforms: [
		.macOS(.v11)
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
