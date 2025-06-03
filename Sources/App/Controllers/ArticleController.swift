import Fluent
import Vapor
import VaporToOpenAPI

struct ArticleController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes
            .grouped(JWTMiddleware())
            .groupedOpenAPIResponse(statusCode: .unauthorized, description: "Unauthorized")
            .group(
                tags: TagObject(
                    name: "articles",
                    description: "Blog article management",
                    externalDocs: ExternalDocumentationObject(
                        description: "Find out more about articles",
                        url: URL(string: "https://blog-api.com/docs/articles")!
                    )
                )
            ) { articles in
                articles.get(use: self.getAllArticles)
                    .openAPI(
                        summary: "Get all articles",
                        description: "Retrieve all articles, optionally filtered by search query with pagination support",
                        operationId: "getAllArticles",
                        query: [
                            "q": .string,
                            "page": .integer,
                            "perPage": .integer,
                        ],
                        response: .type(APIResponse<[ArticleDTO]>.self),
                        responseContentType: .application(.json),
                        links: [
                            Link("id", in: .response): Link.ArticleID.self
                        ],
                        auth: .blogAuth
                    )

                articles.post(use: self.createArticle)
                    .openAPI(
                        summary: "Create new article",
                        description: "Create a new article",
                        operationId: "createArticle",
                        body: .type(CreateArticleRequest.self),
                        contentType: .application(.json),
                        response: .type(APIResponse<ArticleDTO>.self),
                        responseContentType: .application(.json),
                        links: [
                            Link("id", in: .response): Link.ArticleID.self
                        ],
                        auth: .blogAuth
                    )
                    .response(statusCode: .badRequest, body: .type(APIErrorDTO.self), description: "Invalid input")

                articles
                    .groupedOpenAPIResponse(
                        statusCode: .notFound,
                        body: .type(APIErrorDTO.self),
                        description: "Article not found"
                    )
                    .group(":articleID") { article in
                        article.get(use: self.getArticleById)
                            .openAPI(
                                summary: "Get article by ID",
                                description: "Retrieve a specific article by its ID",
                                operationId: "getArticleById",
                                response: .type(APIResponse<ArticleDTO>.self),
                                responseContentType: .application(.json),
                                links: [
                                    Link("articleID", in: .path): Link.ArticleID.self
                                ],
                                auth: .blogAuth
                            )

                        article.put(use: self.updateArticle)
                            .openAPI(
                                summary: "Update article",
                                description: "Update an existing article",
                                operationId: "updateArticle",
                                body: .type(UpdateArticleRequest.self),
                                contentType: .application(.json),
                                response: .type(APIResponse<ArticleDTO>.self),
                                responseContentType: .application(.json),
                                links: [
                                    Link("articleID", in: .path): Link.ArticleID.self
                                ],
                                auth: .blogAuth
                            )
                            .response(statusCode: .badRequest, body: .type(APIErrorDTO.self), description: "Invalid input")

                        article.delete(use: self.deleteArticle)
                            .openAPI(
                                summary: "Delete article",
                                description: "Delete an existing article",
                                operationId: "deleteArticle",
                                links: [
                                    Link("articleID", in: .path): Link.ArticleID.self
                                ],
                                auth: .blogAuth
                            )
                            .response(statusCode: .noContent, description: "Article deleted successfully")
                    }
            }
    }

    @Sendable
    func getAllArticles(req: Request) async throws -> APIResponse<[ArticleDTO]> {
        let pagination = PaginationRequest(
            page: req.query[Int.self, at: "page"],
            perPage: req.query[Int.self, at: "perPage"]
        )

        let searchQuery = req.query[String.self, at: "q"]

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

        return req.successWithPagination(
            articles,
            currentPage: pagination.validatedPage,
            perPage: pagination.validatedPerPage,
            totalItems: totalItems,
            message: "Articles retrieved successfully"
        )
    }

    @Sendable
    func createArticle(req: Request) async throws -> APIResponse<ArticleDTO> {
        try CreateArticleRequest.validate(content: req)
        let user = try req.auth.require(User.self)

        let article = try req.content.decode(CreateArticleRequest.self).toModel(with: user.requireID())
        try await article.save(on: req.db)

        return req.created(
            article.toDTO(),
            message: "Article created successfully"
        )
    }

    @Sendable
    func getArticleById(req: Request) async throws -> APIResponse<ArticleDTO> {
        guard let article = try await Article.find(req.parameters.get("articleID"), on: req.db) else {
            throw APIError.articleNotFound
        }

        return req.success(
            article.toDTO(),
            message: "Article retrieved successfully"
        )
    }

    @Sendable
    func updateArticle(req: Request) async throws -> APIResponse<ArticleDTO> {
        let user = try req.auth.require(User.self)

        let updatedArticle = try req.content.decode(UpdateArticleRequest.self).toModel(with: user.requireID())

        guard let article = try await Article.find(req.parameters.get("articleID"), on: req.db) else {
            throw APIError.articleNotFound
        }

        article.title = updatedArticle.title
        article.content = updatedArticle.content

        try await article.save(on: req.db)

        return req.success(
            article.toDTO(),
            message: "Article updated successfully"
        )
    }

    @Sendable
    func deleteArticle(req: Request) async throws -> APIResponse<EmptyData> {
        guard let article = try await Article.find(req.parameters.get("articleID"), on: req.db) else {
            throw APIError.articleNotFound
        }
        try await article.delete(on: req.db)

        return req.noContent(
            message: "Article deleted successfully"
        )
    }
}
