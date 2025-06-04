import Fluent

struct AddParentCommentToComment: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Comment.schema)
            .field("parent_comment_id", .uuid, .references("comments", "id", onDelete: .cascade))
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Comment.schema)
            .deleteField("parent_comment_id")
            .update()
    }
}
