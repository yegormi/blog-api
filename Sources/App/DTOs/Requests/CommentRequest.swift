import SwiftOpenAPI
import Vapor
import VaporToOpenAPI

/// Request payload for creating a comment
@OpenAPIDescriptable
struct CommentRequest: Content, WithExample {
    /// Comment content
    let content: String

    static let example = CommentRequest(
        content: "Great article! Thanks for sharing."
    )
}
