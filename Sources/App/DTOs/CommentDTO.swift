import Vapor

struct CommentDTO: Content {
    let id: UUID?
    let content: String

    func toModel() -> Comment {
        let model = Comment()

        model.id = self.id
        model.content = self.content
        return model
    }
}
