import Fluent
import JWT
import Vapor
import VaporToOpenAPI

struct AuthController: RouteCollection, Sendable {
    private let authService: any AuthServiceProtocol
    private let userService: any UserServiceProtocol
    
    init(authService: any AuthServiceProtocol, userService: any UserServiceProtocol) {
        self.authService = authService
        self.userService = userService
    }
    
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
            .groupedOpenAPI(auth: .blogAuth)
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
                        responseContentType: .application(.json)
                    )
                    .response(statusCode: .notFound, body: .type(APIErrorDTO.self), description: "User not found")

                me.post("logout", use: self.logoutUser)
                    .openAPI(
                        summary: "Logout user",
                        description: "Logout user and invalidate tokens",
                        operationId: "logoutUser"
                    )
                    .response(statusCode: .noContent, description: "Successfully logged out")

                me.delete(use: self.deleteUserAccount)
                    .openAPI(
                        summary: "Delete user account",
                        description: "Delete the current user's account",
                        operationId: "deleteUserAccount"
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
                        responseContentType: .application(.json)
                    )
                    .response(statusCode: .badRequest, body: .type(APIErrorDTO.self), description: "Invalid file")

                avatar.on(.DELETE, "remove", use: self.removeUserAvatar)
                    .openAPI(
                        summary: "Remove avatar",
                        description: "Remove the user's avatar image",
                        operationId: "removeUserAvatar",
                        response: .type(APIResponse<UserDTO>.self),
                        responseContentType: .application(.json)
                    )
                    .response(statusCode: .notFound, body: .type(APIErrorDTO.self), description: "Avatar not found")
            }
    }

    @Sendable
    func registerUser(req: Request) async throws -> APIResponse<TokenDTO> {
        try RegisterRequest.validate(content: req)
        let request = try req.content.decode(RegisterRequest.self)
        
        let tokenDTO = try await authService.register(request: request, on: req)
        
        return req.created(
            tokenDTO,
            message: "User registered successfully"
        )
    }

    @Sendable
    func loginUser(req: Request) async throws -> APIResponse<TokenDTO> {
        try LoginRequest.validate(content: req)
        let loginRequest = try req.content.decode(LoginRequest.self)
        
        let tokenDTO = try await authService.login(request: loginRequest, on: req)
        
        return req.success(
            tokenDTO,
            message: "User logged in successfully"
        )
    }

    @Sendable
    func logoutUser(req: Request) async throws -> APIResponse<EmptyData> {
        let user = try req.auth.require(User.self)
        
        try await authService.logout(user: user, on: req)
        
        return req.noContent(
            message: "User logged out successfully"
        )
    }

    @Sendable
    func deleteUserAccount(req: Request) async throws -> APIResponse<EmptyData> {
        let user = try req.auth.require(User.self)
        
        try await authService.deleteUserAccount(user: user, on: req)
        
        return req.noContent(
            message: "User account deleted successfully"
        )
    }

    @Sendable
    func getUserProfile(req: Request) async throws -> APIResponse<UserDTO> {
        let user = try req.auth.require(User.self)
        
        let userDTO = try await authService.getUserProfile(user: user, on: req)
        
        return req.success(
            userDTO,
            message: "User profile retrieved successfully"
        )
    }

    @Sendable
    func uploadUserAvatar(req: Request) async throws -> APIResponse<UserDTO> {
        let user = try req.auth.require(User.self)
        let fileUpload = try req.content.decode(FileUpload.self)
        
        let userDTO = try await userService.uploadAvatar(user: user, file: fileUpload, on: req)
        
        return req.success(
            userDTO,
            message: "Avatar uploaded successfully"
        )
    }

    @Sendable
    func removeUserAvatar(req: Request) async throws -> APIResponse<UserDTO> {
        let user = try req.auth.require(User.self)
        
        let userDTO = try await userService.removeAvatar(user: user, on: req)
        
        return req.success(
            userDTO,
            message: "Avatar removed successfully"
        )
    }
}
