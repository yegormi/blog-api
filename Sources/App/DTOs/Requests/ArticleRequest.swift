import Vapor
import SwiftOpenAPI
import VaporToOpenAPI

@OpenAPIDescriptable
/// Request payload for creating an article
struct ArticleRequest: Content, WithExample {
    /// Article title
    let title: String
    /// Article content
    let content: String
    
    static let example = ArticleRequest(
        title: "My First Blog Post",
        content: "This is the content of my first blog post."
    )
}

@OpenAPIDescriptable
/// Request payload for updating an article
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

extension ArticleRequest: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("title", as: String.self, is: !.empty)
        validations.add("content", as: String.self, is: !.empty)
    }
}

extension ArticleRequest {
    func toModel(with id: User.IDValue) -> Article {
        let model = Article()
        model.$user.id = id
        model.title = self.title
        model.content = self.content

        return model
    }
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
