import Fluent
import JWT
import Vapor

struct BearerAuthenticator: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        /// Get bearer token from Headers
        guard let bearer = request.headers.bearerAuthorization else {
            throw Abort(.unauthorized, reason: "Missing authorization token")
        }
        /// Compare token from DB to the one in request
        guard
            let token = try await Token.query(on: request.db)
                .filter(\.$token == bearer.token)
                .with(\.$user)
                .first()
        else {
            throw Abort(.unauthorized, reason: "Invalid token")
        }
        /// Verify token expiration
        guard let expiresAt = token.expiresAt, expiresAt > Date() else {
            throw Abort(.unauthorized, reason: "Token expired")
        }
        /// Verify JWT signature and payload
        let payload = try request.application.jwt.signers.verify(bearer.token, as: Payload.self)

        guard payload.subject.value == token.user.id?.uuidString else {
            throw Abort(.unauthorized, reason: "Invalid token subject")
        }
        /// Authenticate current session with user
        request.auth.login(token.user)

        return try await next.respond(to: request)
    }
}
