// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "blog-api",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🐘 Fluent driver for Postgres.
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        // 🍃 An expressive, performant, and extensible templating language built for Swift.
        .package(url: "https://github.com/vapor/leaf.git", from: "4.5.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.83.0"),
        // 🔐 JWT-based token library to provide legal methods to create and sign payload
        .package(url: "https://github.com/vapor/jwt.git", from: "5.1.2"),
        // ☁️ Amazon S3 library used to upload and store images
        .package(url: "https://github.com/soto-project/soto", from: "7.7.0"),
        // 🧊 OpenAPI generation for Vapor based projects
        .package(url: "https://github.com/dankinsoid/VaporToOpenAPI.git", from: "4.8.3"),
        // 📄 A Swift YAML encoder and decoder
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "JWT", package: "jwt"),
                .product(name: "SotoS3", package: "soto"),
                .product(name: "VaporToOpenAPI", package: "VaporToOpenAPI"),
                .product(name: "Yams", package: "Yams"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "XCTVapor", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
