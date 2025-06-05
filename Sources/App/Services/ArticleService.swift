import Fluent
import Vapor

protocol ArticleServiceProtocol: Sendable {
    func getAllArticles(pagination: PaginationRequest, searchQuery: String?, user: User, on req: Request) async throws -> PaginatedArticles
    func createArticle(request: CreateArticleRequest, user: User, on req: Request) async throws -> ArticleDTO
    func getArticleById(id: UUID, user: User, on req: Request) async throws -> ArticleDTO
    func updateArticle(id: UUID, request: UpdateArticleRequest, user: User, on req: Request) async throws -> ArticleDTO
    func deleteArticle(id: UUID, on req: Request) async throws
    func likeArticle(articleID: UUID, user: User, on req: Request) async throws
    func unlikeArticle(articleID: UUID, user: User, on req: Request) async throws
    func bookmarkArticle(articleID: UUID, user: User, on req: Request) async throws
    func unbookmarkArticle(articleID: UUID, user: User, on req: Request) async throws
}

struct ArticleService: ArticleServiceProtocol, Sendable {
    func getAllArticles(
        pagination: PaginationRequest,
        searchQuery: String?,
        user: User,
        on req: Request
    ) async throws -> PaginatedArticles {
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
            .with(\.$likes)
            .with(\.$bookmarks)
            .range(pagination.offset ..< (pagination.offset + pagination.validatedPerPage))
            .all()

        let articleDTOs = try articles.map { try $0.toDTO(user: user) }

        return PaginatedArticles(items: articleDTOs, totalItems: totalItems)
    }

    func createArticle(request: CreateArticleRequest, user: User, on req: Request) async throws -> ArticleDTO {
        let article = try request.toModel(with: user.requireID())
        try await article.save(on: req.db)
        return try article.toDTO(user: user)
    }

    func getArticleById(id: UUID, user: User, on req: Request) async throws -> ArticleDTO {
        guard let article = try await Article.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$likes)
            .with(\.$bookmarks)
            .first()
        else {
            throw APIError.articleNotFound
        }

        return try article.toDTO(user: user)
    }

    func updateArticle(id: UUID, request: UpdateArticleRequest, user: User, on req: Request) async throws -> ArticleDTO {
        let updatedArticle = try request.toModel(with: user.requireID())

        guard let article = try await Article.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$likes)
            .with(\.$bookmarks)
            .first()
        else {
            throw APIError.articleNotFound
        }

        article.title = updatedArticle.title
        article.content = updatedArticle.content

        try await article.save(on: req.db)
        return try article.toDTO(user: user)
    }

    func deleteArticle(id: UUID, on req: Request) async throws {
        guard let article = try await Article.find(id, on: req.db) else {
            throw APIError.articleNotFound
        }
        try await article.delete(on: req.db)
    }

    func likeArticle(articleID: UUID, user: User, on req: Request) async throws {
        guard try await Article.find(articleID, on: req.db) != nil else {
            throw APIError.articleNotFound
        }

        let userID = try user.requireID()

        let existingLike = try await ArticleLike.query(on: req.db)
            .filter(\.$article.$id == articleID)
            .filter(\.$user.$id == userID)
            .first()

        if existingLike == nil {
            let like = ArticleLike(articleID: articleID, userID: userID)
            try await like.save(on: req.db)
        }
    }

    func unlikeArticle(articleID: UUID, user: User, on req: Request) async throws {
        guard try await Article.find(articleID, on: req.db) != nil else {
            throw APIError.articleNotFound
        }

        let userID = try user.requireID()

        guard let like = try await ArticleLike.query(on: req.db)
            .filter(\.$article.$id == articleID)
            .filter(\.$user.$id == userID)
            .first()
        else {
            return
        }

        try await like.delete(on: req.db)
    }


    func bookmarkArticle(articleID: UUID, user: User, on req: Request) async throws {
        guard try await Article.find(articleID, on: req.db) != nil else {
            throw APIError.articleNotFound
        }

        let userID = try user.requireID()

        let existingBookmark = try await Bookmark.query(on: req.db)
            .filter(\.$article.$id == articleID)
            .filter(\.$user.$id == userID)
            .first()

        if existingBookmark == nil {
            let bookmark = Bookmark(articleID: articleID, userID: userID)
            try await bookmark.save(on: req.db)
        }
    }

    func unbookmarkArticle(articleID: UUID, user: User, on req: Request) async throws {
        guard try await Article.find(articleID, on: req.db) != nil else {
            throw APIError.articleNotFound
        }

        let userID = try user.requireID()

        guard let bookmark = try await Bookmark.query(on: req.db)
            .filter(\.$article.$id == articleID)
            .filter(\.$user.$id == userID)
            .first()
        else {
            return
        }

        try await bookmark.delete(on: req.db)
    }
}
