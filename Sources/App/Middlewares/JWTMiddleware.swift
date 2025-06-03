import Fluent
import JWT
import Vapor

struct JWTMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        /// Get bearer token from Headers
        guard let bearer = request.headers.bearerAuthorization else {
            throw APIError.missingToken
        }
        /// Compare token from DB to the one in request
        guard
            let token = try await Token.query(on: request.db)
            .filter(\.$token == bearer.token)
            .with(\.$user)
            .first()
        else {
            throw APIError.invalidToken
        }
        /// Verify token expiration
        guard let expiresAt = token.expiresAt, expiresAt > Date() else {
            throw APIError.tokenExpired
        }
        /// Verify JWT signature and payload
        let payload = try await request.jwt.verify(bearer.token, as: Payload.self)

        guard payload.subject.value == token.user.id?.uuidString else {
            throw APIError.invalidToken
        }
        /// Authenticate current session with user
        request.auth.login(token.user)

        return try await next.respond(to: request)
    }
}
