import Fluent
import Foundation

final class Bookmark: Model, @unchecked Sendable {
    static let schema = "bookmarks"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "article_id")
    var article: Article

    @Parent(key: "user_id")
    var user: User

    @Timestamp(key: "created_at", on: .create, format: .iso8601(withMilliseconds: true))
    var createdAt: Date?

    init() {}

    init(id: UUID? = nil, articleID: Article.IDValue, userID: User.IDValue) {
        self.id = id
        self.$article.id = articleID
        self.$user.id = userID
    }
}
