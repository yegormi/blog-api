import Fluent
import JWT
import Vapor

protocol AuthServiceProtocol: Sendable {
    func register(request: RegisterRequest, on req: Request) async throws -> TokenDTO
    func login(request: LoginRequest, on req: Request) async throws -> TokenDTO
    func logout(user: User, on req: Request) async throws
    func getUserProfile(user: User, on req: Request) async throws -> UserDTO
    func deleteUserAccount(user: User, on req: Request) async throws
}

struct AuthService: AuthServiceProtocol, Sendable {
    func register(request: RegisterRequest, on req: Request) async throws -> TokenDTO {
        let normalizedUsername = request.username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = request.email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if try await User.query(on: req.db)
            .filter(\.$username == normalizedUsername)
            .first() != nil {
            throw APIError.usernameAlreadyExists
        }

        if try await User.query(on: req.db)
            .filter(\.$email == normalizedEmail)
            .first() != nil {
            throw APIError.emailAlreadyExists
        }

        let user = try User(
            username: request.username,
            email: request.email,
            passwordHash: Bcrypt.hash(request.password)
        )
        try await user.save(on: req.db)

        let token = try await user.generateToken(on: req)
        try await token.save(on: req.db)

        return token.toDTO(with: user.toDTO(on: req))
    }

    func login(request: LoginRequest, on req: Request) async throws -> TokenDTO {
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == request.email)
            .with(\.$avatar)
            .first()
        else {
            throw APIError.invalidCredentials
        }

        guard try Bcrypt.verify(request.password, created: user.passwordHash) else {
            throw APIError.invalidCredentials
        }

        let token = try await user.generateToken(on: req)
        try await token.save(on: req.db)

        return token.toDTO(with: user.toDTO(on: req))
    }

    func logout(user: User, on req: Request) async throws {
        try await Token.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .delete()
    }

    func getUserProfile(user: User, on req: Request) async throws -> UserDTO {
        guard let userDB = try await User.query(on: req.db)
            .filter(\.$id == user.requireID())
            .with(\.$avatar)
            .first()
        else {
            throw APIError.userNotFound
        }

        return userDB.toDTO(on: req)
    }

    func deleteUserAccount(user: User, on req: Request) async throws {
        try await req.db.transaction { transaction in
            if let avatar = try await user.$avatar.get(on: transaction) {
                try await req.fileStorage.deleteFile(key: avatar.key)
            }
            try await user.delete(on: transaction)
        }
    }
}
