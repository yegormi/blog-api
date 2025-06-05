import Fluent
import Foundation

final class ArticleLike: Model, @unchecked Sendable {
    static let schema = "article_likes"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "article_id")
    var article: Article

    @Parent(key: "user_id")
    var user: User

    @Timestamp(key: "created_at", on: .create, format: .iso8601(withMilliseconds: true))
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update, format: .iso8601(withMilliseconds: true))
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, articleID: Article.IDValue, userID: User.IDValue) {
        self.id = id
        self.$article.id = articleID
        self.$user.id = userID
    }
}
