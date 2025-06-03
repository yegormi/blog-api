import Fluent
import JWT
import Vapor

struct Payload: JWTPayload, Equatable {
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case issuedAt = "iat"
    }

    var subject: SubjectClaim
    var expiration: ExpirationClaim
    var issuedAt: IssuedAtClaim

    func verify(using _: some JWTAlgorithm) async throws {
        try self.expiration.verifyNotExpired()
    }
}

final class Token: Model, @unchecked Sendable {
    static let schema = "tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "token")
    var token: String

    @Parent(key: "user_id")
    var user: User

    @Timestamp(key: "expires_at", on: .none, format: .iso8601(withMilliseconds: true))
    var expiresAt: Date?

    init() {}

    init(id: UUID? = nil, token: String, userID: User.IDValue, expiresAt: Date) {
        self.id = id
        self.token = token
        self.$user.id = userID
        self.expiresAt = expiresAt
    }
}

extension Token {
    func toDTO(with user: UserDTO) -> TokenDTO {
        .init(token: self.token, user: user)
    }
}

extension Token: ModelTokenAuthenticatable {
    static var valueKey: KeyPath<Token, Field<String>> { \.$token }
    static var userKey: KeyPath<Token, Parent<User>> { \.$user }

    var isValid: Bool {
        guard let expiresAt = self.expiresAt else { return false }
        return expiresAt > Date()
    }
}
