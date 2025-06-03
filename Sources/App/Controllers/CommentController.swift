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
                        description: "Retrieve all comments for a specific article with pagination support",
                        operationId: "getArticleComments",
                        query: [
                            "page": .integer,
                            "perPage": .integer,
                        ],
                        response: .type(APIResponse<[CommentDTO]>.self),
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
                        response: .type(APIResponse<CommentDTO>.self),
                        responseContentType: .application(.json),
                        links: [
                            Link("articleID", in: .path): Link.ArticleID.self,
                            Link("id", in: .response): Link.CommentID.self,
                        ],
                        auth: .blogAuth
                    )
                    .response(statusCode: .badRequest, body: .type(APIErrorDTO.self), description: "Invalid input")

                comments
                    .groupedOpenAPIResponse(
                        statusCode: .notFound,
                        body: .type(APIErrorDTO.self),
                        description: "Comment not found"
                    )
                    .group(":commentID") { comment in
                        comment.get(use: self.getCommentById)
                            .openAPI(
                                summary: "Get comment by ID",
                                description: "Retrieve a specific comment by its ID",
                                operationId: "getCommentById",
                                response: .type(APIResponse<CommentDTO>.self),
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
                                response: .type(APIResponse<CommentDTO>.self),
                                responseContentType: .application(.json),
                                links: [
                                    Link("articleID", in: .path): Link.ArticleID.self,
                                    Link("commentID", in: .path): Link.CommentID.self,
                                ],
                                auth: .blogAuth
                            )
                            .response(statusCode: .badRequest, body: .type(APIErrorDTO.self), description: "Invalid input")
                            .response(
                                statusCode: .forbidden,
                                body: .type(APIErrorDTO.self),
                                description: "Forbidden - not comment author"
                            )

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
                            .response(
                                statusCode: .forbidden,
                                body: .type(APIErrorDTO.self),
                                description: "Forbidden - not comment author"
                            )
                    }
            }
    }

    @Sendable
    func getArticleComments(req: Request) async throws -> APIResponse<[CommentDTO]> {
        guard let articleID = req.parameters.get("articleID", as: UUID.self) else {
            throw APIError.invalidParameter
        }

        let pagination = PaginationRequest(
            page: req.query[Int.self, at: "page"],
            perPage: req.query[Int.self, at: "perPage"]
        )

        let query = Comment.query(on: req.db)
            .filter(\.$article.$id == articleID)
            .with(\.$user)

        let totalItems = try await query.count()

        let comments = try await query
            .range(pagination.offset ..< (pagination.offset + pagination.validatedPerPage))
            .all()
            .map { $0.toDTO(on: req) }

        return req.successWithPagination(
            comments,
            currentPage: pagination.validatedPage,
            perPage: pagination.validatedPerPage,
            totalItems: totalItems,
            message: "Article comments retrieved successfully"
        )
    }

    @Sendable
    func createComment(req: Request) async throws -> APIResponse<CommentDTO> {
        let user = try req.auth.require(User.self)

        let createComment = try req.content.decode(CommentRequest.self)
        guard let articleID = req.parameters.get("articleID", as: UUID.self) else {
            throw APIError.invalidParameter
        }
        let comment = try Comment(content: createComment.content, articleID: articleID, userID: user.requireID())
        try await comment.save(on: req.db)

        guard let savedComment = try await Comment.query(on: req.db)
            .filter(\.$id == comment.id!)
            .with(\.$user)
            .first() else {
            throw APIError.databaseError
        }

        return req.created(
            savedComment.toDTO(on: req),
            message: "Comment created successfully"
        )
    }

    @Sendable
    func getCommentById(req: Request) async throws -> APIResponse<CommentDTO> {
        guard let commentId = req.parameters.get("commentID", as: UUID.self) else {
            throw APIError.invalidParameter
        }
        guard let comment = try await Comment.query(on: req.db)
            .filter(\.$id == commentId)
            .with(\.$user)
            .first() else {
            throw APIError.commentNotFound
        }

        return req.success(
            comment.toDTO(on: req),
            message: "Comment retrieved successfully"
        )
    }

    @Sendable
    func updateComment(req: Request) async throws -> APIResponse<CommentDTO> {
        let user = try req.auth.require(User.self)

        let updatedComment = try req.content.decode(CommentRequest.self)
        guard let commentId = req.parameters.get("commentID", as: UUID.self) else {
            throw APIError.invalidParameter
        }
        guard let comment = try await Comment.query(on: req.db)
            .filter(\.$id == commentId)
            .with(\.$user)
            .first() else {
            throw APIError.commentNotFound
        }
        guard try comment.$user.id == user.requireID() else {
            throw APIError.resourceOwnershipRequired
        }
        comment.content = updatedComment.content
        try await comment.save(on: req.db)

        return req.success(
            comment.toDTO(on: req),
            message: "Comment updated successfully"
        )
    }

    @Sendable
    func deleteComment(req: Request) async throws -> APIResponse<EmptyData> {
        let user = try req.auth.require(User.self)
        guard let comment = try await Comment.find(req.parameters.get("commentID"), on: req.db) else {
            throw APIError.commentNotFound
        }
        guard try comment.$user.id == user.requireID() else {
            throw APIError.resourceOwnershipRequired
        }
        try await comment.delete(on: req.db)

        return req.noContent(
            message: "Comment deleted successfully"
        )
    }
}
