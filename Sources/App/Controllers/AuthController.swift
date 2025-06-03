import Fluent
import JWT
import Vapor
import VaporToOpenAPI

struct AuthController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authenticated = routes.grouped(JWTMiddleware())

        routes
            .groupedOpenAPIResponse(statusCode: .badRequest, body: .type(APIErrorDTO.self), description: "Invalid input")
            .group(
                tags: TagObject(
                    name: "auth",
                    description: "User authentication and registration",
                    externalDocs: ExternalDocumentationObject(
                        description: "Find out more about authentication",
                        url: URL(string: "https://blog-api.com/docs/auth")!
                    )
                )
            ) { auth in
                auth.post("register", use: self.registerUser)
                    .openAPI(
                        summary: "Register new user",
                        description: "Create a new user account",
                        operationId: "registerUser",
                        body: .type(RegisterRequest.self),
                        contentType: .application(.json),
                        response: .type(APIResponse<TokenDTO>.self),
                        responseContentType: .application(.json)
                    )
                    .response(statusCode: .conflict, body: .type(APIErrorDTO.self), description: "User already exists")
                
                auth.post("login", use: self.loginUser)
                    .openAPI(
                        summary: "Login user",
                        description: "Authenticate user and return token",
                        operationId: "loginUser",
                        body: .type(LoginRequest.self),
                        contentType: .application(.json),
                        response: .type(APIResponse<TokenDTO>.self),
                        responseContentType: .application(.json)
                    )
                    .response(statusCode: .unauthorized, body: .type(APIErrorDTO.self), description: "Invalid credentials")
            }

        authenticated
            .groupedOpenAPIResponse(statusCode: .unauthorized, body: .type(APIErrorDTO.self), description: "Unauthorized")
            .group(
                tags: TagObject(
                    name: "me",
                    description: "User profile management",
                    externalDocs: ExternalDocumentationObject(
                        description: "Find out more about user profiles",
                        url: URL(string: "https://your-blog-api.com/docs/profile")!
                    )
                )
            ) { me in
                me.get(use: self.getUserProfile)
                    .openAPI(
                        summary: "Get user profile",
                        description: "Get the current user's profile information",
                        operationId: "getUserProfile",
                        response: .type(APIResponse<UserDTO>.self),
                        responseContentType: .application(.json),
                        auth: .blogAuth
                    )
                    .response(statusCode: .notFound, body: .type(APIErrorDTO.self), description: "User not found")
                
                me.post("logout", use: self.logoutUser)
                    .openAPI(
                        summary: "Logout user",
                        description: "Logout user and invalidate tokens",
                        operationId: "logoutUser",
                        auth: .blogAuth
                    )
                    .response(statusCode: .noContent, description: "Successfully logged out")
                
                me.delete(use: self.deleteUserAccount)
                    .openAPI(
                        summary: "Delete user account",
                        description: "Delete the current user's account",
                        operationId: "deleteUserAccount",
                        auth: .blogAuth
                    )
                    .response(statusCode: .noContent, description: "Account deleted successfully")
                
                let avatar = me.grouped("avatar")
                avatar.on(.POST, "upload", body: .collect(maxSize: "10mb"), use: self.uploadUserAvatar)
                    .openAPI(
                        summary: "Upload avatar",
                        description: "Upload an avatar image for the user",
                        operationId: "uploadUserAvatar",
                        body: .type(FileUpload.self),
                        contentType: .multipart(.formData),
                        response: .type(APIResponse<UserDTO>.self),
                        responseContentType: .application(.json),
                        auth: .blogAuth
                    )
                    .response(statusCode: .badRequest, body: .type(APIErrorDTO.self), description: "Invalid file")
                
                avatar.on(.DELETE, "remove", use: self.removeUserAvatar)
                    .openAPI(
                        summary: "Remove avatar",
                        description: "Remove the user's avatar image",
                        operationId: "removeUserAvatar",
                        response: .type(APIResponse<UserDTO>.self),
                        responseContentType: .application(.json),
                        auth: .blogAuth
                    )
                    .response(statusCode: .notFound, body: .type(APIErrorDTO.self), description: "Avatar not found")
            }
    }

    @Sendable
    func registerUser(req: Request) async throws -> APIResponse<TokenDTO> {
        try RegisterRequest.validate(content: req)
        let request = try req.content.decode(RegisterRequest.self)

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

        return req.created(
            token.toDTO(with: user.toDTO(on: req)),
            message: "User registered successfully"
        )
    }

    @Sendable
    func loginUser(req: Request) async throws -> APIResponse<TokenDTO> {
        try LoginRequest.validate(content: req)
        let loginRequest = try req.content.decode(LoginRequest.self)

        guard let user = try await User.query(on: req.db)
            .filter(\.$email == loginRequest.email)
            .with(\.$avatar)
            .first()
        else {
            throw APIError.invalidCredentials
        }

        guard try Bcrypt.verify(loginRequest.password, created: user.passwordHash) else {
            throw APIError.invalidCredentials
        }

        let token = try await user.generateToken(on: req)
        try await token.save(on: req.db)

        return req.success(
            token.toDTO(with: user.toDTO(on: req)),
            message: "User logged in successfully"
        )
    }

    @Sendable
    func logoutUser(req: Request) async throws -> APIResponse<EmptyData> {
        let user = try req.auth.require(User.self)
        /// Invalidate all tokens for the user or the specific token used for the request
        try await Token.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .delete()
        
        return req.noContent(
            message: "User logged out successfully"
        )
    }

    @Sendable
    func deleteUserAccount(req: Request) async throws -> APIResponse<EmptyData> {
        let user = try req.auth.require(User.self)

        try await req.db.transaction { transaction in
            if let avatar = try await user.$avatar.get(on: transaction) {
                try await req.fileStorage.deleteFile(key: avatar.key)
            }
            try await user.delete(on: transaction)
        }

        return req.noContent(
            message: "User account deleted successfully"
        )
    }

    @Sendable
    func getUserProfile(req: Request) async throws -> APIResponse<UserDTO> {
        let user = try req.auth.require(User.self)

        guard let userDB = try await User.query(on: req.db)
            .filter(\.$id == user.requireID())
            .with(\.$avatar)
            .first()
        else {
            throw APIError.userNotFound
        }

        return req.success(
            userDB.toDTO(on: req),
            message: "User profile retrieved successfully"
        )
    }

    @Sendable
    func uploadUserAvatar(req: Request) async throws -> APIResponse<UserDTO> {
        let user = try req.auth.require(User.self)
        let file = try req.content.decode(FileUpload.self).file

        guard let fileExtension = file.extension else {
            throw APIError.invalidFileFormat
        }

        let fileName = "\(UUID().uuidString.lowercased()).\(fileExtension)"
        let key = "avatars/\(fileName)"

        let userDTO = try await req.db.transaction { transaction in
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
                throw APIError.userNotFound
            }

            return userDB.toDTO(on: req)
        }
        
        return req.success(
            userDTO,
            message: "Avatar uploaded successfully"
        )
    }

    @Sendable
    func removeUserAvatar(req: Request) async throws -> APIResponse<UserDTO> {
        let user = try req.auth.require(User.self)

        let userDTO = try await req.db.transaction { transaction in
            guard let avatar = try await user.$avatar.get(on: transaction) else {
                throw APIError.avatarNotFound
            }
            try await req.fileStorage.deleteFile(key: avatar.key)
            try await avatar.delete(on: transaction)

            guard let userDB = try await User.query(on: transaction)
                .filter(\.$id == user.requireID())
                .with(\.$avatar)
                .first()
            else {
                throw APIError.userNotFound
            }

            return userDB.toDTO(on: req)
        }
        
        return req.success(
            userDTO,
            message: "Avatar removed successfully"
        )
    }
}
