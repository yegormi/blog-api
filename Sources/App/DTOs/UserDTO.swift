import Fluent
import Vapor

struct UserDTO: Content {
    let id: UUID?
    let username: String
}
