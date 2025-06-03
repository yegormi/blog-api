import Vapor
import VaporToOpenAPI

struct APIErrorDTO: AbortError {
    let status: HTTPStatus
    let error: String
    let message: String
    let path: String
    let timestamp: String
    
    init(
        status: HTTPStatus,
        error: String,
        message: String,
        path: String
    ) {
        self.status = status
        self.error = error
        self.message = message
        self.path = path
        self.timestamp = ISO8601DateFormatter().string(from: Date())
    }
}

extension APIErrorDTO: WithExample {
    static let example = APIErrorDTO(
        status: .notFound,
        error: "Not Found",
        message: "The requested resource was not found.",
        path: "/articles"
    )
}

extension APIErrorDTO {
    static func articleNotFound(path: String) -> APIErrorDTO {
        APIErrorDTO(
            status: .notFound,
            error: "Not Found",
            message: "The requested article was not found.",
            path: path
        )
    }
    
    static func userNotFound(path: String) -> APIErrorDTO {
        APIErrorDTO(
            status: .notFound,
            error: "Not Found",
            message: "The requested user was not found.",
            path: path
        )
    }
    
    static func invalidCredentials(path: String) -> APIErrorDTO {
        APIErrorDTO(
            status: .unauthorized,
            error: "Unauthorized",
            message: "Invalid username or password.",
            path: path
        )
    }
    
    static func badRequest(message: String, path: String) -> APIErrorDTO {
        APIErrorDTO(
            status: .badRequest,
            error: "Bad Request",
            message: message,
            path: path
        )
    }
    
    static func forbidden(message: String, path: String) -> APIErrorDTO {
        APIErrorDTO(
            status: .forbidden,
            error: "Forbidden",
            message: message,
            path: path
        )
    }
    
    static func conflict(message: String, path: String) -> APIErrorDTO {
        APIErrorDTO(
            status: .conflict,
            error: "Conflict",
            message: message,
            path: path
        )
    }
    
    static func internalServerError(message: String, path: String) -> APIErrorDTO {
        APIErrorDTO(
            status: .internalServerError,
            error: "Internal Server Error",
            message: message,
            path: path
        )
    }
}
