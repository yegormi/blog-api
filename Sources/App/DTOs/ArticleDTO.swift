import SwiftOpenAPI
import Vapor
import VaporToOpenAPI

/// Article data transfer object
@OpenAPIDescriptable
struct ArticleDTO: Content, WithExample {
    /// Unique identifier for the article
    var id: UUID?
    /// Article title
    var title: String?
    /// Article content
    var content: String?
    /// ID of the user who created the article
    var userId: User.IDValue?
    /// When the article was created
    let createdAt: String?
    /// When the article was last updated
    let updatedAt: String?

    func toModel(with id: User.IDValue) -> Article {
        let model = Article()

        model.id = self.id
        model.$user.id = id

        if let title = self.title {
            model.title = title
        }
        if let content = self.content {
            model.content = content
        }
        return model
    }

    static let example = ArticleDTO(
        id: UUID(),
        title: "Sample Article",
        content: "This is a sample article content for OpenAPI documentation.",
        userId: UUID(),
        createdAt: "2023-12-01T10:00:00Z",
        updatedAt: "2023-12-01T12:00:00Z"
    )
}
