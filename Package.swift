// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Cadence",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CadenceApp", targets: ["CadenceApp"]),
        .library(name: "CadenceCore", targets: ["CadenceCore"]),
        .library(name: "CadenceUI", targets: ["CadenceUI"])
    ],
    targets: [
        .target(
            name: "CadenceCore",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "CadenceUI",
            dependencies: [
                "CadenceCore"
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "CadenceApp",
            dependencies: [
                "CadenceCore",
                "CadenceUI"
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CadenceCoreTests",
            dependencies: [
                "CadenceCore"
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-load-plugin-library",
                    "/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib"
                ])
            ]
        ),
        .testTarget(
            name: "CadenceUITests",
            dependencies: [
                "CadenceUI"
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-load-plugin-library",
                    "/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib"
                ])
            ]
        )
    ]
)
