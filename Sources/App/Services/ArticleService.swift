import Fluent
import Vapor

protocol ArticleServiceProtocol: Sendable {
    func getAllArticles(pagination: PaginationRequest, searchQuery: String?, on req: Request) async throws -> PaginatedArticles
    func createArticle(request: CreateArticleRequest, user: User, on req: Request) async throws -> ArticleDTO
    func getArticleById(id: UUID, on req: Request) async throws -> ArticleDTO
    func updateArticle(id: UUID, request: UpdateArticleRequest, user: User, on req: Request) async throws -> ArticleDTO
    func deleteArticle(id: UUID, on req: Request) async throws
}

struct ArticleService: ArticleServiceProtocol, Sendable {
    func getAllArticles(pagination: PaginationRequest, searchQuery: String?, on req: Request) async throws -> PaginatedArticles {
        var query = Article.query(on: req.db)

        if let searchQuery {
            let queryNormalized = searchQuery.lowercased()
            query = query.group(.or) { group in
                group.filter(\.$title ~~ queryNormalized)
                group.filter(\.$content ~~ queryNormalized)
            }
        }

        let totalItems = try await query.count()

        let articles = try await query
            .range(pagination.offset ..< (pagination.offset + pagination.validatedPerPage))
            .all()
            .map { $0.toDTO() }

        return PaginatedArticles(items: articles, totalItems: totalItems)
    }

    func createArticle(request: CreateArticleRequest, user: User, on req: Request) async throws -> ArticleDTO {
        let article = try request.toModel(with: user.requireID())
        try await article.save(on: req.db)
        return article.toDTO()
    }

    func getArticleById(id: UUID, on req: Request) async throws -> ArticleDTO {
        guard let article = try await Article.find(id, on: req.db) else {
            throw APIError.articleNotFound
        }
        return article.toDTO()
    }

    func updateArticle(id: UUID, request: UpdateArticleRequest, user: User, on req: Request) async throws -> ArticleDTO {
        let updatedArticle = try request.toModel(with: user.requireID())

        guard let article = try await Article.find(id, on: req.db) else {
            throw APIError.articleNotFound
        }

        article.title = updatedArticle.title
        article.content = updatedArticle.content

        try await article.save(on: req.db)
        return article.toDTO()
    }

    func deleteArticle(id: UUID, on req: Request) async throws {
        guard let article = try await Article.find(id, on: req.db) else {
            throw APIError.articleNotFound
        }
        try await article.delete(on: req.db)
    }
}