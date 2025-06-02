import Fluent
import Vapor

struct ArticleController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let articles = routes
            .grouped("articles")
            .grouped(JWTMiddleware())

        articles.get(use: self.index)
        articles.post(use: self.create)
        articles.group(":articleID") { article in
            article.get(use: self.show)
            article.put(use: self.update)
            article.delete(use: self.delete)
        }
    }

    @Sendable
    func index(req: Request) async throws -> [ArticleDTO] {
        if let query = req.query[String.self, at: "q"] {
            let queryNormalized = query.lowercased()
            return try await Article.query(on: req.db)
                .group(.or) { group in
                    group.filter(\.$title ~~ queryNormalized)
                    group.filter(\.$content ~~ queryNormalized)
                }
                .all()
                .map { $0.toDTO() }
        } else {
            return try await Article.query(on: req.db)
                .all()
                .map { $0.toDTO() }
        }
    }

    @Sendable
    func create(req: Request) async throws -> ArticleDTO {
        try ArticleRequest.validate(content: req)
        let user = try req.auth.require(User.self)

        let article = try req.content.decode(ArticleRequest.self).toModel(with: user.requireID())
        try await article.save(on: req.db)
        return article.toDTO()
    }

    @Sendable
    func show(req: Request) async throws -> ArticleDTO {
        guard let article = try await Article.find(req.parameters.get("articleID"), on: req.db) else {
            throw APIError.articleNotFound
        }
        return article.toDTO()
    }

    @Sendable
    func update(req: Request) async throws -> ArticleDTO {
        let user = try req.auth.require(User.self)

        let updatedArticle = try req.content.decode(ArticleDTO.self).toModel(with: user.requireID())

        guard let article = try await Article.find(req.parameters.get("articleID"), on: req.db) else {
            throw APIError.articleNotFound
        }

        article.title = updatedArticle.title
        article.content = updatedArticle.content

        try await article.save(on: req.db)
        return article.toDTO()
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let article = try await Article.find(req.parameters.get("articleID"), on: req.db) else {
            throw APIError.articleNotFound
        }
        try await article.delete(on: req.db)
        return .noContent
    }
}
