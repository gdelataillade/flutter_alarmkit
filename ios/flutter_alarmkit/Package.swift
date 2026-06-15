// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_alarmkit",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        // If the plugin name contains "_", replace with "-" for the library name.
        .library(name: "flutter-alarmkit", targets: ["flutter_alarmkit"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_alarmkit",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                // The plugin reads/writes shared UserDefaults (a required-reason API) to pass
                // button tint colors to the Live Activity widget, so the privacy manifest is
                // bundled with the plugin. For more information, see
                // https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
