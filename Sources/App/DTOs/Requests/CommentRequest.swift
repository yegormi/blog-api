import Vapor

struct CommentRequest: Content {
    let content: String
}
