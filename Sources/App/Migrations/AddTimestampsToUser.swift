import Fluent

struct AddTimestampsToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("created_at")
            .deleteField("updated_at")
            .update()
    }
}
