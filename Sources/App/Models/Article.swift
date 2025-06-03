import Fluent
import Foundation

final class Article: Model, @unchecked Sendable {
    static let schema = "articles"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String

    @Field(key: "content")
    var content: String

    @Parent(key: "user_id")
    var user: User

    @Children(for: \.$article)
    var comments: [Comment]

    @Timestamp(key: "created_at", on: .create, format: .iso8601(withMilliseconds: true))
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update, format: .iso8601(withMilliseconds: true))
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, title: String, content: String, userID: User.IDValue) {
        self.id = id
        self.title = title
        self.content = content
        self.$user.id = userID
    }
}

extension Article {
    func toDTO() -> ArticleDTO {
        .init(
            id: self.id,
            title: self.title,
            content: self.content,
            userId: self.$user.id,
            createdAt: self.$createdAt.timestamp,
            updatedAt: self.$updatedAt.timestamp
        )
    }
}
