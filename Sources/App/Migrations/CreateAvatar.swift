import Fluent

struct CreateAvatar: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("avatars")
            .id()
            .field("key", .string, .required)
            .field("original_filename", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("created_at", .string)
            .field("updated_at", .string)
            .unique(on: "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("avatars").delete()
    }
}
