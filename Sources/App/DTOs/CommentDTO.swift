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
        createdAt: "2023-12-01T10:00:00Z"
    )
}
