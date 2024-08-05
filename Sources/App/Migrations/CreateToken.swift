import Fluent

struct CreateToken: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("tokens")
            .id()
            .field("token", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("expires_at", .string)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("tokens").delete()
    }
}
