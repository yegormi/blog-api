import SwiftOpenAPI
import Vapor
import VaporToOpenAPI

/// API Error data transfer object
@OpenAPIDescriptable()
struct APIErrorDTO: Error, WithExample {
    /// HTTP status code of the error
    let status: HTTPStatus
    /// Error type or category
    let error: String
    /// Detailed error message
    let message: String
    /// API path where the error occurred
    let path: String
    /// When the error occurred (ISO8601 format)
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
    
    static let example = APIErrorDTO(
        status: .notFound,
        error: "Not Found",
        message: "The requested resource was not found.",
        path: "/resource"
    )
}
