import SwiftOpenAPI
import Vapor
import VaporToOpenAPI

/// Request payload for user login
@OpenAPIDescriptable
struct LoginRequest: Content, Validatable, WithExample {
    /// User's email address
    let email: String
    /// User's password
    let password: String

    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: !.empty)
    }

    static let example = LoginRequest(
        email: "user@example.com",
        password: "password123"
    )
}
