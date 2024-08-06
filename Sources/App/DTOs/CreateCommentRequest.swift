import Vapor

struct CreateCommentRequest: Content {
    let content: String
}
