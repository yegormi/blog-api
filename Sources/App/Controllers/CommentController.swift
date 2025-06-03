import Fluent
import Vapor
import VaporToOpenAPI

struct CommentController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.grouped(JWTMiddleware())
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
                    .response(statusCode: 200, description: "Comments retrieved successfully")
                    .response(statusCode: 400, description: "Invalid article ID")
                    .response(statusCode: 401, description: "Unauthorized")

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
                    .response(statusCode: 201, description: "Comment created successfully")
                    .response(statusCode: 400, description: "Invalid input")
                    .response(statusCode: 401, description: "Unauthorized")
                    .response(statusCode: 404, description: "Article not found")

                comments.group(":commentID") { comment in
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
                        .response(statusCode: 200, description: "Comment retrieved successfully")
                        .response(statusCode: 401, description: "Unauthorized")
                        .response(statusCode: 404, description: "Comment not found")

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
                        .response(statusCode: 200, description: "Comment updated successfully")
                        .response(statusCode: 400, description: "Invalid input")
                        .response(statusCode: 401, description: "Unauthorized")
                        .response(statusCode: 403, description: "Forbidden - not comment author")
                        .response(statusCode: 404, description: "Comment not found")

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
                        .response(statusCode: 204, description: "Comment deleted successfully")
                        .response(statusCode: 401, description: "Unauthorized")
                        .response(statusCode: 403, description: "Forbidden - not comment author")
                        .response(statusCode: 404, description: "Comment not found")
                }
            }
    }

    @Sendable
    func getArticleComments(req: Request) async throws -> [CommentDTO] {
        guard let articleID = req.parameters.get("articleID", as: UUID.self) else {
            throw Abort(.badRequest)
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
            throw Abort(.badRequest)
        }
        let comment = try Comment(content: createComment.content, articleID: articleID, userID: user.requireID())
        try await comment.save(on: req.db)

        guard let savedComment = try await Comment.query(on: req.db)
            .filter(\.$id == comment.id!)
            .with(\.$user)
            .first() else {
            throw Abort(.internalServerError)
        }

        return savedComment.toDTO(on: req)
    }

    @Sendable
    func getCommentById(req: Request) async throws -> CommentDTO {
        guard let commentId = req.parameters.get("commentID", as: UUID.self) else {
            throw Abort(.notFound)
        }
        guard let comment = try await Comment.query(on: req.db)
            .filter(\.$id == commentId)
            .with(\.$user)
            .first() else {
            throw Abort(.notFound)
        }
        return comment.toDTO(on: req)
    }

    @Sendable
    func updateComment(req: Request) async throws -> CommentDTO {
        let user = try req.auth.require(User.self)

        let updatedComment = try req.content.decode(CommentRequest.self)
        guard let commentId = req.parameters.get("commentID", as: UUID.self) else {
            throw Abort(.notFound)
        }
        guard let comment = try await Comment.query(on: req.db)
            .filter(\.$id == commentId)
            .with(\.$user)
            .first() else {
            throw Abort(.notFound)
        }
        guard try comment.$user.id == user.requireID() else {
            throw Abort(.forbidden)
        }
        comment.content = updatedComment.content
        try await comment.save(on: req.db)
        return comment.toDTO(on: req)
    }

    @Sendable
    func deleteComment(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard let comment = try await Comment.find(req.parameters.get("commentID"), on: req.db) else {
            throw Abort(.notFound)
        }
        guard try comment.$user.id == user.requireID() else {
            throw Abort(.forbidden)
        }
        try await comment.delete(on: req.db)
        return .noContent
    }
}
