import Fluent
import FluentPostgresDriver
import JWT
import Leaf
import NIOSSL
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
    ContentConfiguration.global.use(encoder: encoder, for: .json)

    app.http.server.configuration.hostname = Environment.get("APP_URL") ?? "127.0.0.1"
    app.http.server.configuration.port = Int(Environment.get("APP_PORT") ?? "8080") ?? 8080

    try app.databases.use(DatabaseConfigurationFactory.postgres(
        configuration: .init(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
            database: Environment.get("DATABASE_NAME") ?? "vapor_database",
            tls: .prefer(.init(configuration: .clientDefault))
        )
    ), as: .psql)

    app.migrations.add(CreateArticle())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateToken())

    guard let jwtSecret = Environment.get("JWT_SECRET") else {
        fatalError("JWT_SECRET environment variable is not set")
    }
    app.jwt.signers.use(.hs256(key: jwtSecret))

    app.views.use(.leaf)

    // register routes
    try routes(app)
}
