import SwiftOpenAPI
import Vapor
import VaporToOpenAPI

/// Request payload for creating an article
@OpenAPIDescriptable
struct CreateArticleRequest: Content, WithExample {
    /// Article title
    let title: String
    /// Article content
    let content: String

    static let example = CreateArticleRequest(
        title: "My First Blog Post",
        content: "This is the content of my first blog post."
    )
}

extension CreateArticleRequest: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("title", as: String.self, is: !.empty)
        validations.add("content", as: String.self, is: !.empty)
    }
}

extension CreateArticleRequest {
    func toModel(with id: User.IDValue) -> Article {
        let model = Article()
        model.$user.id = id
        model.title = self.title
        model.content = self.content

        return model
    }
}
