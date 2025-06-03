import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(User.schema)
            .id()
            .field("email", .string, .required)
            .field("username", .string, .required)
            .field("password_hash", .string, .required)
            .field("created_at", .string)
            .field("updated_at", .string)
            .unique(on: "username")
            .unique(on: "email")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(User.schema).delete()
    }
}
