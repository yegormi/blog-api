import Fluent
import Foundation
import JWT
import Vapor

final class User: Model, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "username")
    var username: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    @OptionalChild(for: \.$user)
    var avatar: Avatar?

    @Children(for: \.$user)
    var articles: [Article]

    @Timestamp(key: "created_at", on: .create, format: .iso8601)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update, format: .iso8601)
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, username: String, email: String, passwordHash: String) {
        self.id = id
        self.username = username
        self.email = email
        self.passwordHash = passwordHash
    }
}

extension User {
    func toDTO(fileStorage: FileStorageService) -> UserDTO {
        UserDTO(
            id: self.id,
            email: self.email,
            username: self.username,
            avatarUrl: {
                if let avatar = self.$avatar.value, let key = avatar?.key {
                    fileStorage.getFileURL(for: key)
                } else {
                    nil
                }
            }()
        )
    }
}

extension User {
    func generateToken(using app: Application) throws -> Token {
        guard let id = self.id else { throw APIError.userNotFound }

        let expirationTime = Date().addingTimeInterval(1 * 60 * 60) // 1 hour

        let payload = Payload(
            subject: SubjectClaim(value: id.uuidString),
            expiration: ExpirationClaim(value: expirationTime),
            issuedAt: IssuedAtClaim(value: Date())
        )

        let token = try app.jwt.signers.sign(payload)

        return Token(token: token, userID: id, expiresAt: expirationTime)
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}
