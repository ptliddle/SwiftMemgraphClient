// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var platformName: String {
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    return "apple"
    #elseif os(Linux)
    return "linux"
    #else
    return "windows"
    #endif
}

let mgClientVersion = "\"1.4.1\""

let package = Package(
    name: "SwiftMemgraphClient",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "Cmgclient", targets: ["Cmgclient"]),
        .library(name: "SwiftMemgraphClient", targets: ["SwiftMemgraphClient"]),
    ],
    dependencies: [
        // Add the OpenSSL package dependency
        .package(url: "https://github.com/krzyzanowskim/OpenSSL.git", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Cmgclient",
            dependencies: [
                // Link the OpenSSL package to your target
                .product(name: "OpenSSL", package: "OpenSSL")
            ],
            path: "Sources/Cmgclient",
            exclude: [
                "mgclient/build",
                "mgclient/cmake",
                "mgclient/examples",
                "mgclient/mgclient_cpp",
                "mgclient/tests",
                "mgclient/tools",
                "mgclient/wasm"
            ],
            sources: [
                "mgclient/src/\(platformName)/mgsocket.c",
                "mgclient/src/mgallocator.c",
                "mgclient/src/mgclient.c",
                "mgclient/src/mgmessage.c",
                "mgclient/src/mgsession-decoder.c",
                "mgclient/src/mgsession-encoder.c",
                "mgclient/src/mgsession.c",
                "mgclient/src/mgtransport.c",
                "mgclient/src/mgvalue.h",
                "mgclient/src/mgvalue.c"
            ],
            publicHeadersPath: "include",
            cSettings: [
                
                .define("MGCLIENT_VERSION", to: mgClientVersion),
                
                .headerSearchPath("include"),
                .headerSearchPath("mgclient/include"),
                .headerSearchPath("mgclient/src"),
                
                .headerSearchPath("mgclient/src/apple", .when(platforms: [.macOS, .iOS])),
                .define("MGCLIENT_ON_APPLE", to: "1", .when(platforms: [.macOS, .iOS])),
                
                .headerSearchPath("mgclient/src/linux", .when(platforms: [.linux])),
                .define("MGCLIENT_ON_LINUX", to: "1", .when(platforms: [.linux])),
                
                .headerSearchPath("mgclient/src/windows", .when(platforms: [.windows])),
                .define("MGCLIENT_ON_WINDOWS", to: "1", .when(platforms: [.windows]))
            ]
        ),
        .target(
            name: "SwiftMemgraphClient",
            dependencies: ["Cmgclient"]
        ),
        .testTarget(
            name: "SwiftMemgraphClientTests",
            dependencies: ["SwiftMemgraphClient", "Cmgclient"]),
    ]
)

// Use the platformName variable in your code
print("Running on platform: \(platformName)")

// Example usage of the preprocessor definitions
#if MGCLIENT_ON_APPLE
print("MGCLIENT_ON_APPLE is defined")
#endif

#if MGCLIENT_ON_LINUX
print("MGCLIENT_ON_LINUX is defined")
#endif
 
