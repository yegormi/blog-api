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

    @Timestamp(key: "created_at", on: .create, format: .iso8601)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update, format: .iso8601)
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, title: String, content: String) {
        self.id = id
        self.title = title
        self.content = content
    }
}

extension Article {
    func toDTO() -> ArticleDTO {
        .init(
            id: self.id,
            title: self.$title.value,
            content: self.$content.value
        )
    }
}
