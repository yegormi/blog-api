import Fluent

struct CreateArticle: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Article.schema)
            .id()
            .field("title", .string, .required)
            .field("content", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("created_at", .string)
            .field("updated_at", .string)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Article.schema).delete()
    }
}
