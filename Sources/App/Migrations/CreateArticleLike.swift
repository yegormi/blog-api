import Fluent

struct CreateArticleLike: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(ArticleLike.schema)
            .id()
            .field("article_id", .uuid, .required, .references("articles", "id", onDelete: .cascade))
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("is_like", .bool, .required)
            .field("created_at", .string)
            .field("updated_at", .string)
            .unique(on: "article_id", "user_id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(ArticleLike.schema).delete()
    }
}
