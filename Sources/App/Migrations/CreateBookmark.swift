import Fluent

struct CreateBookmark: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Bookmark.schema)
            .id()
            .field("article_id", .uuid, .required, .references("articles", "id", onDelete: .cascade))
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("created_at", .string)
            .unique(on: "article_id", "user_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Bookmark.schema).delete()
    }
}
