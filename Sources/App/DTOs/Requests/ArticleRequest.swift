import Vapor

struct ArticleRequest: Content {
    let title: String
    let content: String
}

struct UpdateArticleRequest: Content {
    let title: String?
    let content: String?
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
