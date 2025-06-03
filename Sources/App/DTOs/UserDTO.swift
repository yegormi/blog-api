import SwiftOpenAPI
import Vapor
import VaporToOpenAPI

/// User data transfer object
@OpenAPIDescriptable
struct UserDTO: Content, WithExample {
    /// Unique identifier for the user
    let id: UUID?
    let username: String
}
