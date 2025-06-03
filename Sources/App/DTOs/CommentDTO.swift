import Vapor

struct CommentDTO: Content {
    let id: UUID?
    let user: UserDTO
    let content: String
    let createdAt: String?

    func toModel() -> Comment {
        let model = Comment()

        model.id = self.id
        model.content = self.content
        return model
    }
}
