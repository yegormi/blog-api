import Fluent
import Vapor
import VaporToOpenAPI

struct CommentController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes
            .grouped(JWTMiddleware())
            .groupedOpenAPIResponse(statusCode: .unauthorized, body: .type(APIErrorDTO.self), description: "Unauthorized")
            .groupedOpenAPIResponse(statusCode: .notFound, body: .type(APIErrorDTO.self), description: "Article not found")
            .grouped("articles", ":articleID")
            .group(
                tags: TagObject(
                    name: "comments",
                    description: "Article comment management",
                    externalDocs: ExternalDocumentationObject(
                        description: "Find out more about comments",
                        url: URL(string: "https://blog-api.com/docs/comments")!
                    )
                )
            ) { comments in
                comments.get(use: self.getArticleComments)
                    .openAPI(
                        summary: "Get article comments",
                        description: "Retrieve all comments for a specific article",
                        operationId: "getArticleComments",
                        response: .type([CommentDTO].self),
                        responseContentType: .application(.json),
                        links: [
                            Link("articleID", in: .path): Link.ArticleID.self,
                            Link("id", in: .response): Link.CommentID.self,
                        ],
                        auth: .blogAuth
                    )
                    .response(statusCode: .badRequest, body: .type(APIErrorDTO.self), description: "Invalid input")

                comments.post(use: self.createComment)
                    .openAPI(
                        summary: "Create comment",
                        description: "Create a new comment on an article",
                        operationId: "createComment",
                        body: .type(CommentRequest.self),
                        contentType: .application(.json),
                        response: .type(CommentDTO.self),
                        responseContentType: .application(.json),
                        links: [
                            Link("articleID", in: .path): Link.ArticleID.self,
                            Link("id", in: .response): Link.CommentID.self,
                        ],
                        auth: .blogAuth
                    )
                    .response(statusCode: .badRequest, body: .type(APIErrorDTO.self), description: "Invalid input")
                    .response(statusCode: .notFound, body: .type(APIErrorDTO.self), description: "Article not found")
                
                comments
                    .groupedOpenAPIResponse(statusCode: .notFound, body: .type(APIErrorDTO.self), description: "Comment not found")
                    .group(":commentID") { comment in
                        comment.get(use: self.getCommentById)
                            .openAPI(
                                summary: "Get comment by ID",
                                description: "Retrieve a specific comment by its ID",
                                operationId: "getCommentById",
                                response: .type(CommentDTO.self),
                                responseContentType: .application(.json),
                                links: [
                                    Link("articleID", in: .path): Link.ArticleID.self,
                                    Link("commentID", in: .path): Link.CommentID.self,
                                ],
                                auth: .blogAuth
                            )
                        
                        comment.put(use: self.updateComment)
                            .openAPI(
                                summary: "Update comment",
                                description: "Update an existing comment (only by the comment author)",
                                operationId: "updateComment",
                                body: .type(CommentRequest.self),
                                contentType: .application(.json),
                                response: .type(CommentDTO.self),
                                responseContentType: .application(.json),
                                links: [
                                    Link("articleID", in: .path): Link.ArticleID.self,
                                    Link("commentID", in: .path): Link.CommentID.self,
                                ],
                                auth: .blogAuth
                            )
                            .response(statusCode: .badRequest, body: .type(APIErrorDTO.self), description: "Invalid input")
                            .response(statusCode: .forbidden, body: .type(APIErrorDTO.self), description: "Forbidden - not comment author")
                            .response(statusCode: .notFound, body: .type(APIErrorDTO.self), description: "Not found")
                        
                        comment.delete(use: self.deleteComment)
                            .openAPI(
                                summary: "Delete comment",
                                description: "Delete an existing comment (only by the comment author)",
                                operationId: "deleteComment",
                                links: [
                                    Link("articleID", in: .path): Link.ArticleID.self,
                                    Link("commentID", in: .path): Link.CommentID.self,
                                ],
                                auth: .blogAuth
                            )
                            .response(statusCode: .noContent, description: "Comment deleted successfully")
                            .response(statusCode: .forbidden, body: .type(APIErrorDTO.self), description: "Forbidden - not comment author")
                    }
            }
    }

    @Sendable
    func getArticleComments(req: Request) async throws -> [CommentDTO] {
        guard let articleID = req.parameters.get("articleID", as: UUID.self) else {
            throw APIErrorDTO.badRequest(message: "Invalid article ID", path: req.url.path)
        }
        return try await Comment.query(on: req.db)
            .filter(\.$article.$id == articleID)
            .with(\.$user)
            .all()
            .map { $0.toDTO(on: req) }
    }

    @Sendable
    func createComment(req: Request) async throws -> CommentDTO {
        let user = try req.auth.require(User.self)

        let createComment = try req.content.decode(CommentRequest.self)
        guard let articleID = req.parameters.get("articleID", as: UUID.self) else {
            throw APIErrorDTO.badRequest(message: "Invalid article ID", path: req.url.path)
        }
        let comment = try Comment(content: createComment.content, articleID: articleID, userID: user.requireID())
        try await comment.save(on: req.db)

        guard let savedComment = try await Comment.query(on: req.db)
            .filter(\.$id == comment.id!)
            .with(\.$user)
            .first() else {
            throw APIErrorDTO.internalServerError(message: "Failed to retrieve created comment", path: req.url.path)
        }

        return savedComment.toDTO(on: req)
    }

    @Sendable
    func getCommentById(req: Request) async throws -> CommentDTO {
        guard let commentId = req.parameters.get("commentID", as: UUID.self) else {
            throw APIErrorDTO.badRequest(message: "Invalid comment ID", path: req.url.path)
        }
        guard let comment = try await Comment.query(on: req.db)
            .filter(\.$id == commentId)
            .with(\.$user)
            .first() else {
            throw APIErrorDTO.badRequest(message: "Comment not found", path: req.url.path)
        }
        return comment.toDTO(on: req)
    }

    @Sendable
    func updateComment(req: Request) async throws -> CommentDTO {
        let user = try req.auth.require(User.self)

        let updatedComment = try req.content.decode(CommentRequest.self)
        guard let commentId = req.parameters.get("commentID", as: UUID.self) else {
            throw APIErrorDTO.badRequest(message: "Invalid comment ID", path: req.url.path)
        }
        guard let comment = try await Comment.query(on: req.db)
            .filter(\.$id == commentId)
            .with(\.$user)
            .first() else {
            throw APIErrorDTO.badRequest(message: "Comment not found", path: req.url.path)
        }
        guard try comment.$user.id == user.requireID() else {
            throw APIErrorDTO.forbidden(message: "You can only modify your own comments", path: req.url.path)
        }
        comment.content = updatedComment.content
        try await comment.save(on: req.db)
        return comment.toDTO(on: req)
    }

    @Sendable
    func deleteComment(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard let comment = try await Comment.find(req.parameters.get("commentID"), on: req.db) else {
            throw APIErrorDTO.badRequest(message: "Comment not found", path: req.url.path)
        }
        guard try comment.$user.id == user.requireID() else {
            throw APIErrorDTO.forbidden(message: "You can only modify your own comments", path: req.url.path)
        }
        try await comment.delete(on: req.db)
        return .noContent
    }
}
