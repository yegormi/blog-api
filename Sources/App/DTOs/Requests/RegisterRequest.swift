import Vapor
import SwiftOpenAPI
import VaporToOpenAPI

@OpenAPIDescriptable
/// Request payload for user registration
struct RegisterRequest: Content, Validatable, WithExample {
    /// Desired username (minimum 2 characters)
    let username: String
    /// User's email address
    let email: String
    /// User's password (minimum 8 characters)
    let password: String

    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty && .count(2...))
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
    
    static let example = RegisterRequest(
        username: "newuser",
        email: "newuser@example.com",
        password: "password123"
    )
}
