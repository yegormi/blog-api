import SwiftOpenAPI
import Vapor
import VaporToOpenAPI

/// Request payload for updating an article
@OpenAPIDescriptable
struct UpdateArticleRequest: Content, WithExample {
    /// Updated article title (optional)
    let title: String?
    /// Updated article content (optional)
    let content: String?

    static let example = UpdateArticleRequest(
        title: "Updated Blog Post Title",
        content: "This is the updated content of my blog post."
    )
}

extension UpdateArticleRequest {
    func toModel(with id: User.IDValue) -> Article {
        let model = Article()
        model.$user.id = id
        if let title = self.title {
            model.title = title
        }
        if let content = self.content {
            model.content = content
        }

        return model
    }
}
