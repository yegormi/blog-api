import SwiftOpenAPI
import Vapor
import VaporToOpenAPI

/// User data transfer object
@OpenAPIDescriptable
struct UserDTO: Content, WithExample {
    /// Unique identifier for the user
    let id: UUID?
    /// Email associated with the user
    let email: String
    /// Unique username of the user
    let username: String
    /// Image, that could be uploaded and stored for user (Optional)
    let avatarUrl: String?
}
