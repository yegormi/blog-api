import Fluent

struct CreateArticle: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("articles")
            .id()
            .field("title", .string, .required)
            .field("content", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("articles").delete()
    }
}
