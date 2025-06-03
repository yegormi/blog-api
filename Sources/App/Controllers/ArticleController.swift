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
                        description: "Retrieve all articles, optionally filtered by search query",
                        operationId: "getAllArticles",
                        query: ["q": .string],
                        response: .type([ArticleDTO].self),
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
                        response: .type(ArticleDTO.self),
                        responseContentType: .application(.json),
                        links: [
                            Link("id", in: .response): Link.ArticleID.self
                        ],
                        auth: .blogAuth
                    )
                    .response(statusCode: .badRequest, body: .type(APIErrorDTO.self), description: "Invalid input")

                articles
                    .groupedOpenAPIResponse(statusCode: .notFound, body: .type(APIErrorDTO.self), description: "Article not found")
                    .group(":articleID") { article in
                        article.get(use: self.getArticleById)
                            .openAPI(
                                summary: "Get article by ID",
                                description: "Retrieve a specific article by its ID",
                                operationId: "getArticleById",
                                response: .type(ArticleDTO.self),
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
                                response: .type(ArticleDTO.self),
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
    func getAllArticles(req: Request) async throws -> [ArticleDTO] {
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
    func createArticle(req: Request) async throws -> ArticleDTO {
        try CreateArticleRequest.validate(content: req)
        let user = try req.auth.require(User.self)

        let article = try req.content.decode(CreateArticleRequest.self).toModel(with: user.requireID())
        try await article.save(on: req.db)
        return article.toDTO()
    }

    @Sendable
    func getArticleById(req: Request) async throws -> ArticleDTO {
        guard let article = try await Article.find(req.parameters.get("articleID"), on: req.db) else {
            throw APIError.articleNotFound
        }
        return article.toDTO()
    }

    @Sendable
    func updateArticle(req: Request) async throws -> ArticleDTO {
        let user = try req.auth.require(User.self)

        let updatedArticle = try req.content.decode(UpdateArticleRequest.self).toModel(with: user.requireID())

        guard let article = try await Article.find(req.parameters.get("articleID"), on: req.db) else {
            throw APIError.articleNotFound
        }

        article.title = updatedArticle.title
        article.content = updatedArticle.content

        try await article.save(on: req.db)
        return article.toDTO()
    }

    @Sendable
    func deleteArticle(req: Request) async throws -> HTTPStatus {
        guard let article = try await Article.find(req.parameters.get("articleID"), on: req.db) else {
            throw APIError.articleNotFound
        }
        try await article.delete(on: req.db)
        return .noContent
    }
}
