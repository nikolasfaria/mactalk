// swift-tools-version: 5.10
import PackageDescription

let vendorLib = "\(Context.packageDirectory)/Vendor/sherpa-onnx/lib"

let package = Package(
    name: "MacTalk",
    platforms: [.macOS(.v14)],
    dependencies: [
        // Thinking Orbs (ThinkingOrbsKit) — https://libraries.dev/orbs
        .package(url: "https://github.com/Jakubantalik/Libraries.dev", branch: "main"),
    ],
    targets: [
        .target(
            name: "CSherpaOnnx",
            path: "Sources/CSherpaOnnx",
            publicHeadersPath: "include"
        ),
        .executableTarget(
            name: "MacTalk",
            dependencies: [
                "CSherpaOnnx",
                .product(name: "ThinkingOrbsKit", package: "Libraries.dev"),
            ],
            path: "Sources/MacTalk",
            linkerSettings: [
                .unsafeFlags(["-L", vendorLib]),
                .linkedLibrary("sherpa-onnx-c-api"),
                .linkedLibrary("onnxruntime"),
                // dev runs use the vendored dylibs; the .app bundle uses Contents/Frameworks
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", vendorLib]),
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"]),
            ]
        ),
    ]
)
