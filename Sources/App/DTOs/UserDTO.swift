import Vapor
import SwiftOpenAPI
import VaporToOpenAPI

@OpenAPIDescriptable
/// User data transfer object
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
