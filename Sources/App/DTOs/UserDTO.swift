import SwiftOpenAPI
import Vapor
import VaporToOpenAPI

/// User data transfer object
@OpenAPIDescriptable
struct UserDTO: Content, WithExample {
    /// Unique identifier for the user
    let id: UUID?
    /// User's email address
    let email: String
    /// User's username
    let username: String
    /// URL to user's avatar image
    let avatarUrl: String?

    static let example = UserDTO(
        id: UUID(),
        email: "user@example.com",
        username: "johndoe",
        avatarUrl: "https://example.com/avatar.jpg"
    )
}
