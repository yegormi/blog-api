import Fluent

struct CreateToken: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Token.schema)
            .id()
            .field("token", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("expires_at", .string)
            .unique(on: "token")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Token.schema).delete()
    }
}
