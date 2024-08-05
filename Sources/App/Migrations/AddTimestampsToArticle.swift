import Fluent

struct AddTimestampsToArticle: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("articles")
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("articles")
            .deleteField("created_at")
            .deleteField("updated_at")
            .update()
    }
}
