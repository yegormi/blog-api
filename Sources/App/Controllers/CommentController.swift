import Fluent
import Vapor
import VaporToOpenAPI

struct CommentController: RouteCollection, Sendable {
    private let commentService: any CommentServiceProtocol

    init(commentService: any CommentServiceProtocol) {
        self.commentService = commentService
    }

    func boot(routes: any RoutesBuilder) throws {
        routes
            .grouped(JWTMiddleware())
            .groupedOpenAPI(auth: .blogAuth)
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
                        ]
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
                        ]
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
                                ]
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
                                ]
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
                                ]
                            )
                            .response(statusCode: .noContent, description: "Comment deleted successfully")
                            .response(
                                statusCode: .forbidden,
                                body: .type(APIErrorDTO.self),
                                description: "Forbidden - not comment author"
                            )

                        comment.post("replies", use: self.createReply)
                            .openAPI(
                                summary: "Create reply",
                                description: "Create a reply to an existing comment",
                                operationId: "createReply",
                                body: .type(CommentRequest.self),
                                contentType: .application(.json),
                                response: .type(APIResponse<CommentDTO>.self),
                                responseContentType: .application(.json),
                                links: [
                                    Link("articleID", in: .path): Link.ArticleID.self,
                                    Link("commentID", in: .path): Link.CommentID.self,
                                    Link("id", in: .response): Link.CommentID.self,
                                ]
                            )
                            .response(statusCode: .badRequest, body: .type(APIErrorDTO.self), description: "Invalid input")

                        comment.get("replies", use: self.getCommentReplies)
                            .openAPI(
                                summary: "Get comment replies",
                                description: "Retrieve all replies for a specific comment with pagination support",
                                operationId: "getCommentReplies",
                                query: [
                                    "page": .integer,
                                    "perPage": .integer,
                                ],
                                response: .type(APIResponse<[CommentDTO]>.self),
                                responseContentType: .application(.json),
                                links: [
                                    Link("articleID", in: .path): Link.ArticleID.self,
                                    Link("commentID", in: .path): Link.CommentID.self,
                                    Link("id", in: .response): Link.CommentID.self,
                                ]
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

        let result = try await commentService.getArticleComments(articleID: articleID, pagination: pagination, on: req)

        return req.successWithPagination(
            result.items,
            currentPage: pagination.validatedPage,
            perPage: pagination.validatedPerPage,
            totalItems: result.totalItems,
            message: "Article comments retrieved successfully"
        )
    }

    @Sendable
    func createComment(req: Request) async throws -> APIResponse<CommentDTO> {
        let user = try req.auth.require(User.self)
        let request = try req.content.decode(CommentRequest.self)

        guard let articleID = req.parameters.get("articleID", as: UUID.self) else {
            throw APIError.invalidParameter
        }

        let commentDTO = try await commentService.createComment(request: request, articleID: articleID, user: user, on: req)

        return req.created(
            commentDTO,
            message: "Comment created successfully"
        )
    }

    @Sendable
    func getCommentById(req: Request) async throws -> APIResponse<CommentDTO> {
        guard let commentId = req.parameters.get("commentID", as: UUID.self) else {
            throw APIError.invalidParameter
        }

        let commentDTO = try await commentService.getCommentById(id: commentId, on: req)

        return req.success(
            commentDTO,
            message: "Comment retrieved successfully"
        )
    }

    @Sendable
    func updateComment(req: Request) async throws -> APIResponse<CommentDTO> {
        let user = try req.auth.require(User.self)
        let request = try req.content.decode(CommentRequest.self)

        guard let commentId = req.parameters.get("commentID", as: UUID.self) else {
            throw APIError.invalidParameter
        }

        let commentDTO = try await commentService.updateComment(id: commentId, request: request, user: user, on: req)

        return req.success(
            commentDTO,
            message: "Comment updated successfully"
        )
    }

    @Sendable
    func deleteComment(req: Request) async throws -> APIResponse<EmptyData> {
        let user = try req.auth.require(User.self)

        guard let commentId = req.parameters.get("commentID", as: UUID.self) else {
            throw APIError.invalidParameter
        }

        try await self.commentService.deleteComment(id: commentId, user: user, on: req)

        return req.noContent(
            message: "Comment deleted successfully"
        )
    }

    @Sendable
    func createReply(req: Request) async throws -> APIResponse<CommentDTO> {
        let user = try req.auth.require(User.self)
        let request = try req.content.decode(CommentRequest.self)

        guard let articleID = req.parameters.get("articleID", as: UUID.self) else {
            throw APIError.invalidParameter
        }

        guard let parentCommentID = req.parameters.get("commentID", as: UUID.self) else {
            throw APIError.invalidParameter
        }

        let commentDTO = try await commentService.createReply(
            request: request,
            articleID: articleID,
            parentCommentID: parentCommentID,
            user: user,
            on: req
        )

        return req.created(
            commentDTO,
            message: "Reply created successfully"
        )
    }

    @Sendable
    func getCommentReplies(req: Request) async throws -> APIResponse<[CommentDTO]> {
        guard let commentID = req.parameters.get("commentID", as: UUID.self) else {
            throw APIError.invalidParameter
        }

        let pagination = PaginationRequest(
            page: req.query[Int.self, at: "page"],
            perPage: req.query[Int.self, at: "perPage"]
        )

        let result = try await commentService.getCommentReplies(parentCommentID: commentID, pagination: pagination, on: req)

        return req.successWithPagination(
            result.items,
            currentPage: pagination.validatedPage,
            perPage: pagination.validatedPerPage,
            totalItems: result.totalItems,
            message: "Comment replies retrieved successfully"
        )
    }
}
