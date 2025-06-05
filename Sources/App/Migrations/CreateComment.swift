import Fluent

struct CreateComment: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Comment.schema)
            .id()
            .field("content", .string, .required)
            .field("article_id", .uuid, .required, .references("articles", "id", onDelete: .cascade))
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("parent_id", .uuid, .references("comments", "id", onDelete: .cascade))
            .field("created_at", .string)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Comment.schema).delete()
    }
}
