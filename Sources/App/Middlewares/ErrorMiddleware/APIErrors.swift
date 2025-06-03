import Vapor

/// Structure containing static API error definitions
struct APIError: APIErrorProtocol {
    let status: HTTPStatus
    let message: String
}

extension APIError {
    // MARK: - 400 Bad Request
    static let badRequest = APIError(
        status: .badRequest,
        message: "The request was invalid."
    )
    
    static let invalidJSON = APIError(
        status: .badRequest,
        message: "Invalid JSON format in request body."
    )
    
    static let missingRequiredFields = APIError(
        status: .badRequest,
        message: "Required fields are missing."
    )
    
    static let invalidEmail = APIError(
        status: .badRequest,
        message: "Invalid email format."
    )
    
    static let invalidPassword = APIError(
        status: .badRequest,
        message: "Password does not meet requirements."
    )
    
    static let invalidFileFormat = APIError(
        status: .badRequest,
        message: "Invalid file format."
    )
    
    static let fileTooLarge = APIError(
        status: .badRequest,
        message: "File size exceeds maximum limit."
    )
    
    static let invalidParameter = APIError(
        status: .badRequest,
        message: "Invalid parameter provided."
    )
    
    // MARK: - 401 Unauthorized
    static let unauthorized = APIError(
        status: .unauthorized,
        message: "Authentication required."
    )
    
    static let invalidCredentials = APIError(
        status: .unauthorized,
        message: "Invalid username or password."
    )
    
    static let tokenExpired = APIError(
        status: .unauthorized,
        message: "Authorization token has expired."
    )
    
    static let invalidToken = APIError(
        status: .unauthorized,
        message: "Invalid authorization token."
    )
    
    static let missingToken = APIError(
        status: .unauthorized,
        message: "Missing authorization token."
    )
    
    // MARK: - 403 Forbidden
    static let forbidden = APIError(
        status: .forbidden,
        message: "Access to this resource is forbidden."
    )
    
    static let insufficientPermissions = APIError(
        status: .forbidden,
        message: "Insufficient permissions to perform this action."
    )
    
    static let accountSuspended = APIError(
        status: .forbidden,
        message: "Account has been suspended."
    )
    
    static let resourceOwnershipRequired = APIError(
        status: .forbidden,
        message: "You can only access resources that you own."
    )
    
    // MARK: - 404 Not Found
    static let notFound = APIError(
        status: .notFound,
        message: "The requested resource was not found."
    )
    
    static let articleNotFound = APIError(
        status: .notFound,
        message: "The requested article was not found."
    )
    
    static let userNotFound = APIError(
        status: .notFound,
        message: "The requested user was not found."
    )
    
    static let commentNotFound = APIError(
        status: .notFound,
        message: "The requested comment was not found."
    )
    
    static let endpointNotFound = APIError(
        status: .notFound,
        message: "API endpoint not found."
    )
    
    static let avatarNotFound = APIError(
        status: .notFound,
        message: "User does not have an avatar."
    )
    
    // MARK: - 409 Conflict
    static let conflict = APIError(
        status: .conflict,
        message: "The request conflicts with the current state of the resource."
    )
    
    static let emailAlreadyExists = APIError(
        status: .conflict,
        message: "An account with this email already exists."
    )
    
    static let usernameAlreadyExists = APIError(
        status: .conflict,
        message: "This username is already taken."
    )
    
    static let resourceAlreadyExists = APIError(
        status: .conflict,
        message: "Resource already exists."
    )
    
    // MARK: - 422 Unprocessable Entity
    static let unprocessableEntity = APIError(
        status: .unprocessableEntity,
        message: "The request was well-formed but was unable to be followed due to semantic errors."
    )
    
    static let validationFailed = APIError(
        status: .unprocessableEntity,
        message: "Validation failed for one or more fields."
    )
    
    // MARK: - 429 Too Many Requests
    static let tooManyRequests = APIError(
        status: .tooManyRequests,
        message: "Too many requests. Please try again later."
    )
    
    static let rateLimitExceeded = APIError(
        status: .tooManyRequests,
        message: "Rate limit exceeded. Please slow down your requests."
    )
    
    // MARK: - 500 Internal Server Error
    static let internalServerError = APIError(
        status: .internalServerError,
        message: "Something went wrong."
    )
    
    static let databaseError = APIError(
        status: .internalServerError,
        message: "Database operation failed."
    )
    
    static let externalServiceError = APIError(
        status: .internalServerError,
        message: "External service is currently unavailable."
    )
    
    // MARK: - 502 Bad Gateway
    static let badGateway = APIError(
        status: .badGateway,
        message: "Bad gateway response from upstream server."
    )
    
    // MARK: - 503 Service Unavailable
    static let serviceUnavailable = APIError(
        status: .serviceUnavailable,
        message: "Service is temporarily unavailable."
    )
    
    static let maintenanceMode = APIError(
        status: .serviceUnavailable,
        message: "Service is under maintenance."
    )
    
    // MARK: - Custom Message Factory Methods
    static func badRequest(message: String) -> APIError {
        APIError(status: .badRequest, message: message)
    }
    
    static func unauthorized(message: String) -> APIError {
        APIError(status: .unauthorized, message: message)
    }
    
    static func forbidden(message: String) -> APIError {
        APIError(status: .forbidden, message: message)
    }
    
    static func notFound(message: String) -> APIError {
        APIError(status: .notFound, message: message)
    }
    
    static func conflict(message: String) -> APIError {
        APIError(status: .conflict, message: message)
    }
    
    static func unprocessableEntity(message: String) -> APIError {
        APIError(status: .unprocessableEntity, message: message)
    }
    
    static func internalServerError(message: String) -> APIError {
        APIError(status: .internalServerError, message: message)
    }
    
    // MARK: - Validation Specific Errors
    static func fieldRequired(_ field: String) -> APIError {
        APIError(status: .badRequest, message: "Field '\(field)' is required.")
    }
    
    static func fieldTooShort(_ field: String, minLength: Int) -> APIError {
        APIError(status: .badRequest, message: "Field '\(field)' must be at least \(minLength) characters long.")
    }
    
    static func fieldTooLong(_ field: String, maxLength: Int) -> APIError {
        APIError(status: .badRequest, message: "Field '\(field)' must not exceed \(maxLength) characters.")
    }
    
    static func invalidFieldValue(_ field: String) -> APIError {
        APIError(status: .badRequest, message: "Invalid value for field '\(field)'.")
    }
}
