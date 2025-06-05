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
    func toDTO(on req: Request, includeReplies: Bool = false) async throws -> CommentDTO {
        if includeReplies {
            try await self.$user.load(on: req.db)
            try await self.$replies.load(on: req.db)

            for reply in self.replies {
                try await self.loadRepliesRecursively(reply, on: req)
            }
        } else {
            try await self.$user.load(on: req.db)
        }

        let replies: [CommentDTO]? = try await includeReplies ? self.replies.asyncMap {
            try await $0.toDTO(on: req, includeReplies: true)
        } : nil

        return .init(
            id: self.id,
            user: self.user.toDTO(on: req),
            content: self.content,
            createdAt: self.$createdAt.timestamp,
            parentCommentId: self.$parentComment.id,
            replies: replies,
            replyCount: self.replies.count
        )
    }

    private func loadRepliesRecursively(_ comment: Comment, on req: Request) async throws {
        try await comment.$replies.load(on: req.db)

        for reply in comment.replies {
            try await self.loadRepliesRecursively(reply, on: req)
        }
    }
}
