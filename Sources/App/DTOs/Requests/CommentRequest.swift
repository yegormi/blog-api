import Vapor
import SwiftOpenAPI
import VaporToOpenAPI

@OpenAPIDescriptable
/// Request payload for creating a comment
struct CommentRequest: Content, WithExample {
    /// Comment content
    let content: String
    
    static let example = CommentRequest(
        content: "Great article! Thanks for sharing."
    )
}
