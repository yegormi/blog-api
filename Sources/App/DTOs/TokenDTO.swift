import Vapor
import SwiftOpenAPI
import VaporToOpenAPI

@OpenAPIDescriptable
/// Authentication token data transfer object
struct TokenDTO: Content, WithExample {
    /// Authentication token string
    let token: String
    /// User associated with the token
    let user: UserDTO
    
    static let example = TokenDTO(
        token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        user: UserDTO.example
    )
}
