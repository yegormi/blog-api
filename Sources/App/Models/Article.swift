import Fluent
import Foundation
import Vapor

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

    @Children(for: \.$article)
    var likes: [ArticleLike]

    @Children(for: \.$article)
    var bookmarks: [Bookmark]

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
    func toDTO(user: User) throws -> ArticleDTO {
        let isLiked = try self.$likes.value?.contains { try $0.$user.id == user.requireID() } ?? false
        let isBookmarked = try self.$bookmarks.value?.contains { try $0.$user.id == user.requireID() } ?? false
        
        return .init(
            id: self.id,
            title: self.title,
            content: self.content,
            userId: self.$user.id,
            createdAt: self.$createdAt.timestamp,
            updatedAt: self.$updatedAt.timestamp,
            likesCount: self.$likes.value?.count ?? 0,
            isLiked: isLiked,
            isBookmarked: isBookmarked
        )
    }
}
