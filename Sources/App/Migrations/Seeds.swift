import Fluent
import Vapor

struct Seeds: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Create users
        let user1 = try await createUser(username: "john_doe", email: "john@example.com", password: "password123", on: database)
        let user2 = try await createUser(username: "jane_smith", email: "jane@example.com", password: "password456", on: database)

        // Create articles
        let article1 = try await createArticle(
            title: "First Article",
            content: "This is the content of the first article.",
            user: user1,
            on: database
        )
        let article2 = try await createArticle(
            title: "Second Article",
            content: "This is the content of the second article.",
            user: user2,
            on: database
        )

        // Create comments
        try await createComment(content: "Great article!", article: article1, user: user2, on: database)
        try await createComment(content: "I learned a lot, thanks!", article: article1, user: user1, on: database)
        try await createComment(content: "Interesting perspective.", article: article2, user: user1, on: database)
    }

    func revert(on database: Database) async throws {
        try await Comment.query(on: database).delete()
        try await Article.query(on: database).delete()
        try await User.query(on: database).delete()
    }

    private func createUser(username: String, email: String, password: String, on database: Database) async throws -> User {
        let user = try User(
            username: username,
            email: email,
            passwordHash: Bcrypt.hash(password)
        )
        try await user.save(on: database)
        return user
    }

    private func createArticle(title: String, content: String, user: User, on database: Database) async throws -> Article {
        let article = try Article(
            title: title,
            content: content,
            userID: user.requireID()
        )
        try await article.save(on: database)
        return article
    }

    private func createComment(content: String, article: Article, user: User, on database: Database) async throws {
        let comment = try Comment(
            content: content,
            articleID: article.requireID(),
            userID: user.requireID()
        )
        try await comment.save(on: database)
    }
}
