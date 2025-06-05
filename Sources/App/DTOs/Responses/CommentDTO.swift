import SwiftOpenAPI
import Vapor
import VaporToOpenAPI

/// Comment data transfer object
@OpenAPIDescriptable
struct CommentDTO: Content, WithExample {
    /// Unique identifier for the comment
    let id: UUID?
    /// User who created the comment
    let user: UserDTO
    /// Comment content
    let content: String
    /// When the comment was created
    let createdAt: String?
    /// Parent ID if this is a reply
    let parentID: UUID?
    /// Replies to this comment
    let replies: [CommentDTO]?
    /// Total number of replies
    let replyCount: Int

    func toModel() -> Comment {
        let model = Comment()

        model.id = self.id
        model.content = self.content
        return model
    }

    static let example = CommentDTO(
        id: UUID(),
        user: UserDTO.example,
        content: "This is a sample comment.",
        createdAt: "2023-12-01T10:00:00Z",
        parentID: nil,
        replies: [.reply1, .reply2],
        replyCount: 2
    )

    static let reply1 = CommentDTO(
        id: UUID(),
        user: UserDTO.example,
        content: "This is a reply to the comment.",
        createdAt: "2023-12-01T10:05:00Z",
        parentID: UUID(),
        replies: nil,
        replyCount: 0
    )

    static let reply2 = CommentDTO(
        id: UUID(),
        user: UserDTO.example,
        content: "This is second reply to the comment.",
        createdAt: "2023-12-01T10:06:00Z",
        parentID: UUID(),
        replies: nil,
        replyCount: 0
    )
}
