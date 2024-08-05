import Fluent
import JWT
import Vapor

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("login", use: self.login)
        auth.post("register", use: self.register)

        let protected = auth.grouped(BearerAuthenticator())
        protected.get("me", use: self.getMe)
    }

    @Sendable
    func register(req: Request) async throws -> UserDTO {
        try RegisterRequest.validate(content: req)
        let request = try req.content.decode(RegisterRequest.self)

        let normalizedUsername = request.username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = request.email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if username already exists
        if
            let _ = try await User.query(on: req.db)
                .filter(\.$username == normalizedUsername)
                .first()
        {
            throw Abort(.conflict, reason: "A user with this username already exists")
        }

        // Check if email already exists
        if
            let _ = try await User.query(on: req.db)
                .filter(\.$email == normalizedEmail)
                .first()
        {
            throw Abort(.conflict, reason: "A user with this email already exists")
        }

        let user = try User(
            username: request.username,
            email: request.email,
            passwordHash: Bcrypt.hash(request.password)
        )
        try await user.save(on: req.db)
        return user.toDTO()
    }

    @Sendable
    func login(req: Request) async throws -> TokenDTO {
        try LoginRequest.validate(content: req)
        let loginRequest = try req.content.decode(LoginRequest.self)

        guard
            let user = try await User.query(on: req.db)
                .filter(\.$email == loginRequest.email)
                .first()
        else {
            throw Abort(.unauthorized, reason: "Invalid email")
        }

        guard try Bcrypt.verify(loginRequest.password, created: user.passwordHash) else {
            throw Abort(.unauthorized, reason: "Invalid password")
        }

        let bearer = try user.generateToken(using: req.application)
        try await bearer.save(on: req.db)
        req.auth.login(user)

        return TokenDTO(token: bearer.token, user: user.toDTO())
    }

    @Sendable
    func getMe(req: Request) async throws -> UserDTO {
        let user = try req.auth.require(User.self)
        return user.toDTO()
    }
}
