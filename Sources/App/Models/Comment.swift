import Fluent
import Vapor

final class Comment: Model, @unchecked Sendable {
    static let schema = "comments"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "content")
    var content: String

    @Parent(key: "article_id")
    var article: Article

    @Parent(key: "user_id")
    var user: User

    @OptionalParent(key: "parent_comment_id")
    var parentComment: Comment?

    @Children(for: \.$parentComment)
    var replies: [Comment]

    @Timestamp(key: "created_at", on: .create, format: .iso8601(withMilliseconds: true))
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        content: String,
        articleID: Article.IDValue,
        userID: User.IDValue,
        parentCommentID: Comment.IDValue? = nil
    ) {
        self.id = id
        self.content = content
        self.$article.id = articleID
        self.$user.id = userID
        if let parentCommentID {
            self.$parentComment.id = parentCommentID
        }
    }
}

extension Comment {
    func toDTO(on req: Request, includeReplies: Bool = false) -> CommentDTO {
        let replies: [CommentDTO]? = includeReplies ? self.replies.map { $0.toDTO(on: req, includeReplies: false) } : nil

        return .init(
            id: self.id,
            user: self.user.toDTO(on: req),
            content: self.content,
            createdAt: self.$createdAt.timestamp,
            parentCommentId: self.$parentComment.id,
            replies: replies
        )
    }
}
