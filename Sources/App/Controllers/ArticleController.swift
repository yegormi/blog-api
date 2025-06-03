import Fluent
import Vapor
import VaporToOpenAPI

struct ArticleController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes
            .grouped("articles")
            .grouped(JWTMiddleware())
            .group(
                tags: TagObject(
                    name: "articles",
                    description: "Blog article management",
                    externalDocs: ExternalDocumentationObject(
                        description: "Find out more about articles",
                        url: URL(string: "https://your-blog-api.com/docs/articles")!
                    )
                )
            ) { articles in
                
                articles.get(use: self.index)
                    .openAPI(
                        summary: "Get all articles",
                        description: "Retrieve all articles, optionally filtered by search query",
                        query: ["q": .string],
                        response: .type([ArticleDTO].self),
                        responseContentType: .application(.json),
                        auth: .blogAuth
                    )
                
                articles.post(use: self.create)
                    .openAPI(
                        summary: "Create new article",
                        description: "Create a new article",
                        body: .type(CreateArticleRequest.self),
                        contentType: .application(.json),
                        response: .type(ArticleDTO.self),
                        responseContentType: .application(.json),
                        auth: .blogAuth
                    )
                    .response(statusCode: 400, description: "Invalid input")
                    .response(statusCode: 401, description: "Unauthorized")
                
                articles.group(":articleID") { article in
                    article.get(use: self.show)
                        .openAPI(
                            summary: "Get article by ID",
                            description: "Retrieve a specific article by its ID",
                            response: .type(ArticleDTO.self),
                            responseContentType: .application(.json),
                            auth: .blogAuth
                        )
                        .response(statusCode: 404, description: "Article not found")
                    
                    article.put(use: self.update)
                        .openAPI(
                            summary: "Update article",
                            description: "Update an existing article",
                            body: .type(UpdateArticleRequest.self),
                            contentType: .application(.json),
                            response: .type(ArticleDTO.self),
                            responseContentType: .application(.json),
                            auth: .blogAuth
                        )
                        .response(statusCode: 400, description: "Invalid input")
                        .response(statusCode: 401, description: "Unauthorized")
                        .response(statusCode: 404, description: "Article not found")
                    
                    article.delete(use: self.delete)
                        .openAPI(
                            summary: "Delete article",
                            description: "Delete an existing article",
                            auth: .blogAuth
                        )
                        .response(statusCode: 204, description: "Article deleted successfully")
                        .response(statusCode: 401, description: "Unauthorized")
                        .response(statusCode: 404, description: "Article not found")
                }
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
        try CreateArticleRequest.validate(content: req)
        let user = try req.auth.require(User.self)
        
        let article = try req.content.decode(CreateArticleRequest.self).toModel(with: user.requireID())
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
