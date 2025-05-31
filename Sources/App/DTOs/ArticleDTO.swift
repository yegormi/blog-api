import Vapor

struct ArticleDTO: Content {
    var id: UUID?
    var title: String?
    var content: String?
    var userId: User.IDValue?
    let createdAt: String?
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
}
