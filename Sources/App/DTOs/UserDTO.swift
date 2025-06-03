import Vapor

struct UserDTO: Content {
    let id: UUID?
    let email: String
    let username: String
    let avatarUrl: String?
}
