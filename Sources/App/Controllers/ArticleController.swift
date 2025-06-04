import Fluent
import Vapor
import VaporToOpenAPI

struct ArticleController: RouteCollection, Sendable {
    private let articleService: any ArticleServiceProtocol
    
    init(articleService: any ArticleServiceProtocol) {
        self.articleService = articleService
    }
    
    func boot(routes: any RoutesBuilder) throws {
        routes
            .grouped(JWTMiddleware())
            .groupedOpenAPI(auth: .blogAuth)
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
                        ]
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
                        ]
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
                                ]
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
                                ]
                            )
                            .response(statusCode: .badRequest, body: .type(APIErrorDTO.self), description: "Invalid input")

                        article.delete(use: self.deleteArticle)
                            .openAPI(
                                summary: "Delete article",
                                description: "Delete an existing article",
                                operationId: "deleteArticle",
                                links: [
                                    Link("articleID", in: .path): Link.ArticleID.self
                                ]
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
        
        let result = try await articleService.getAllArticles(pagination: pagination, searchQuery: searchQuery, on: req)
        
        return req.successWithPagination(
            result.items,
            currentPage: pagination.validatedPage,
            perPage: pagination.validatedPerPage,
            totalItems: result.totalItems,
            message: "Articles retrieved successfully"
        )
    }

    @Sendable
    func createArticle(req: Request) async throws -> APIResponse<ArticleDTO> {
        try CreateArticleRequest.validate(content: req)
        let user = try req.auth.require(User.self)
        let request = try req.content.decode(CreateArticleRequest.self)
        
        let articleDTO = try await articleService.createArticle(request: request, user: user, on: req)
        
        return req.created(
            articleDTO,
            message: "Article created successfully"
        )
    }

    @Sendable
    func getArticleById(req: Request) async throws -> APIResponse<ArticleDTO> {
        guard let articleID = req.parameters.get("articleID", as: UUID.self) else {
            throw APIError.invalidParameter
        }
        
        let articleDTO = try await articleService.getArticleById(id: articleID, on: req)
        
        return req.success(
            articleDTO,
            message: "Article retrieved successfully"
        )
    }

    @Sendable
    func updateArticle(req: Request) async throws -> APIResponse<ArticleDTO> {
        let user = try req.auth.require(User.self)
        let request = try req.content.decode(UpdateArticleRequest.self)
        
        guard let articleID = req.parameters.get("articleID", as: UUID.self) else {
            throw APIError.invalidParameter
        }
        
        let articleDTO = try await articleService.updateArticle(id: articleID, request: request, user: user, on: req)
        
        return req.success(
            articleDTO,
            message: "Article updated successfully"
        )
    }

    @Sendable
    func deleteArticle(req: Request) async throws -> APIResponse<EmptyData> {
        guard let articleID = req.parameters.get("articleID", as: UUID.self) else {
            throw APIError.invalidParameter
        }
        
        try await articleService.deleteArticle(id: articleID, on: req)
        
        return req.noContent(
            message: "Article deleted successfully"
        )
    }
}
