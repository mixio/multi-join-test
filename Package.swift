// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "MultiJoinTest",
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),

        // 🔵 Swift ORM (queries, models, relations, etc) built.
        .package(url: "https://github.com/mixio/fluent-sqlite.git", branch: "table-aliases-and-resultset-occurrences"),
        .package(url: "https://github.com/mixio/fluent-mysql.git", branch: "table-aliases-and-resultset-occurrences"),
        .package(url: "https://github.com/mixio/fluent-postgresql.git", branch: "table-aliases-and-resultset-occurrences"),

        .package(url: "https://github.com/mixio/jjtools.git", from: "0.1.0"),

    ],
    targets: [
        .target(name: "App", dependencies: ["Vapor", "FluentSQLite", "FluentMySQL", "FluentPostgreSQL", "JJTools"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

