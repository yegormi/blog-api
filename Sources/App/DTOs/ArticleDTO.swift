import Fluent
import Vapor

struct ArticleDTO: Content {
    var id: UUID?
    var title: String?
    var content: String?

    func toModel() -> Article {
        let model = Article()

        model.id = self.id
        if let title = self.title {
            model.title = title
        }
        if let content = self.content {
            model.content = content
        }
        return model
    }
}
