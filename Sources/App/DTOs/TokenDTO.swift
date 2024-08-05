import Fluent
import Vapor

struct TokenDTO: Content {
    let token: String
    let user: UserDTO
}
