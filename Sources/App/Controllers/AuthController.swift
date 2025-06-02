import Fluent
import JWT
import Vapor

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authenticated = routes.grouped(JWTMiddleware())

        let auth = routes.grouped("auth")
        auth.post("register", use: self.register)
        auth.post("login", use: self.login)

        let me = authenticated.grouped("me")
        me.get(use: self.getProfile)
        me.post("logout", use: self.logout)
        me.delete(use: self.deleteAccount)

        let avatar = me.grouped("avatar")
        avatar.on(.POST, "upload", body: .collect(maxSize: "10mb"), use: self.uploadAvatar)
        avatar.on(.DELETE, "remove", use: self.removeAvatar)
    }

    @Sendable
    func register(req: Request) async throws -> UserDTO {
        try RegisterRequest.validate(content: req)
        let request = try req.content.decode(RegisterRequest.self)

        let normalizedUsername = request.username.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = request.email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if try await User.query(on: req.db)
            .filter(\.$username == normalizedUsername)
            .first() != nil {
            throw Abort(.conflict, reason: "A user with this username already exists")
        }

        if try await User.query(on: req.db)
            .filter(\.$email == normalizedEmail)
            .first() != nil {
            throw Abort(.conflict, reason: "A user with this email already exists")
        }

        let user = try User(
            username: request.username,
            email: request.email,
            passwordHash: Bcrypt.hash(request.password)
        )
        try await user.save(on: req.db)
        return user.toDTO(on: req)
    }

    @Sendable
    func login(req: Request) async throws -> TokenDTO {
        try LoginRequest.validate(content: req)
        let loginRequest = try req.content.decode(LoginRequest.self)

        guard let user = try await User.query(on: req.db)
            .filter(\.$email == loginRequest.email)
            .with(\.$avatar)
            .first()
        else {
            throw Abort(.unauthorized, reason: "Invalid email")
        }

        guard try Bcrypt.verify(loginRequest.password, created: user.passwordHash) else {
            throw Abort(.unauthorized, reason: "Invalid password")
        }

        let token = try await user.generateToken(on: req)
        try await token.save(on: req.db)

        return token.toDTO(with: user.toDTO(on: req))
    }

    @Sendable
    func logout(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        /// Invalidate all tokens for the user or the specific token used for the request
        try await Token.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .delete()
        return .noContent
    }

    @Sendable
    func deleteAccount(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)

        try await req.db.transaction { transaction in
            if let avatar = try await user.$avatar.get(on: transaction) {
                try await req.fileStorage.deleteFile(key: avatar.key)
            }
            try await user.delete(on: transaction)
        }

        return .noContent
    }

    @Sendable
    func getProfile(req: Request) async throws -> UserDTO {
        let user = try req.auth.require(User.self)

        guard let userDB = try await User.query(on: req.db)
            .filter(\.$id == user.requireID())
            .with(\.$avatar)
            .first()
        else {
            throw Abort(.badRequest, reason: "No user found")
        }

        return userDB.toDTO(on: req)
    }

    @Sendable
    func uploadAvatar(req: Request) async throws -> UserDTO {
        let user = try req.auth.require(User.self)
        let file = try req.content.decode(FileUpload.self).file

        guard let fileExtension = file.extension else {
            throw Abort(.badRequest, reason: "Malformed file")
        }

        let fileName = "\(UUID().uuidString.lowercased()).\(fileExtension)"
        let key = "avatars/\(fileName)"

        return try await req.db.transaction { transaction in
            /// Delete old avatar if it exists
            if let existingAvatar = try await user.$avatar.get(on: transaction) {
                try await req.fileStorage.deleteFile(key: existingAvatar.key)
                try await existingAvatar.delete(on: transaction)
            }

            /// Upload new avatar
            _ = try await req.fileStorage.uploadFile(file, key: key)

            /// Create new Avatar
            let avatar = try Avatar(key: key, originalFilename: file.filename, userID: user.requireID())
            try await user.$avatar.create(avatar, on: transaction)

            guard let userDB = try await User.query(on: transaction)
                .filter(\.$id == user.requireID())
                .with(\.$avatar)
                .first()
            else {
                throw Abort(.badRequest, reason: "No user found")
            }

            return userDB.toDTO(on: req)
        }
    }

    @Sendable
    func removeAvatar(req: Request) async throws -> UserDTO {
        let user = try req.auth.require(User.self)

        return try await req.db.transaction { transaction in
            guard let avatar = try await user.$avatar.get(on: transaction) else {
                throw Abort(.notFound, reason: "User does not have an avatar")
            }
            try await req.fileStorage.deleteFile(key: avatar.key)
            try await avatar.delete(on: transaction)

            guard let userDB = try await User.query(on: transaction)
                .filter(\.$id == user.requireID())
                .with(\.$avatar)
                .first()
            else {
                throw Abort(.badRequest, reason: "No user found")
            }

            return userDB.toDTO(on: req)
        }
    }
}
