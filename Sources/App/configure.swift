import Fluent
import FluentPostgresDriver
import JWT
import Leaf
import NIOSSL
import SotoCore
import SotoS3
@preconcurrency import SwiftOpenAPI
import Vapor

public func configure(_ app: Application) async throws {
    app.middleware.use(
        FileMiddleware(
            publicDirectory: app.directory.publicDirectory,
            defaultFile: "index.html"
        )
    )

    DateEncodingFormat.default = .dateTime

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    ContentConfiguration.global.use(encoder: encoder, for: .json)

    let awsClient = AWSClient(
        credentialProvider: .static(
            accessKeyId: Environment.get("AWS_ACCESS_KEY_ID") ?? "",
            secretAccessKey: Environment.get("AWS_SECRET_ACCESS_KEY") ?? ""
        )
    )

    let s3Configuration = S3Configuration(
        bucketName: Environment.get("AWS_S3_BUCKET_NAME") ?? "",
        region: .init(rawValue: Environment.get("AWS_REGION") ?? "")
    )

    app.awsClient = awsClient
    app.fileStorage = S3Service(client: app.awsClient, config: s3Configuration)

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

    app.migrations.add(CreateUser())
    app.migrations.add(CreateToken())
    app.migrations.add(CreateAvatar())
    app.migrations.add(CreateArticle())
    app.migrations.add(CreateComment())

    guard let jwtSecret = Environment.get("JWT_SECRET") else {
        preconditionFailure("JWT_SECRET environment variable is not set")
    }
    await app.jwt.keys.add(hmac: .init(from: jwtSecret), digestAlgorithm: .sha256)

    app.views.use(.leaf)

    // register routes
    try routes(app)
}
