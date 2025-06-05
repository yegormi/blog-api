import Fluent
import Vapor

protocol CommentServiceProtocol: Sendable {
    func getArticleComments(articleID: UUID, pagination: PaginationRequest, on req: Request) async throws -> PaginatedComments
    func createComment(request: CommentRequest, articleID: UUID, user: User, on req: Request) async throws -> CommentDTO
    func getCommentById(id: UUID, on req: Request) async throws -> CommentDTO
    func updateComment(id: UUID, request: CommentRequest, user: User, on req: Request) async throws -> CommentDTO
    func deleteComment(id: UUID, user: User, on req: Request) async throws
    func createReply(request: CommentRequest, articleID: UUID, parentID: UUID, user: User, on req: Request) async throws
        -> CommentDTO
    func getCommentReplies(parentID: UUID, pagination: PaginationRequest, on req: Request) async throws -> PaginatedReplies
}

struct CommentService: CommentServiceProtocol, Sendable {
    func getArticleComments(articleID: UUID, pagination: PaginationRequest, on req: Request) async throws -> PaginatedComments {
        let query = Comment.query(on: req.db)
            .filter(\.$article.$id == articleID)
            .filter(\.$parent.$id == .null)
            .with(\.$user)

        let totalItems = try await query.count()

        let comments = try await query
            .range(pagination.offset ..< (pagination.offset + pagination.validatedPerPage))
            .all()
            .asyncMap { try await $0.toDTO(on: req, includeReplies: true) }

        return PaginatedComments(items: comments, totalItems: totalItems)
    }

    func createComment(request: CommentRequest, articleID: UUID, user: User, on req: Request) async throws -> CommentDTO {
        let comment = try Comment(content: request.content, articleID: articleID, userID: user.requireID())
        try await comment.save(on: req.db)

        guard let savedComment = try await Comment.query(on: req.db)
            .filter(\.$id == comment.id!)
            .with(\.$user)
            .first()
        else {
            throw APIError.databaseError
        }

        return try await savedComment.toDTO(on: req, includeReplies: true)
    }

    func getCommentById(id: UUID, on req: Request) async throws -> CommentDTO {
        guard let comment = try await Comment.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$user)
            .first()
        else {
            throw APIError.commentNotFound
        }

        return try await comment.toDTO(on: req, includeReplies: true)
    }

    func updateComment(id: UUID, request: CommentRequest, user: User, on req: Request) async throws -> CommentDTO {
        guard let comment = try await Comment.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$user)
            .first()
        else {
            throw APIError.commentNotFound
        }

        guard try comment.$user.id == user.requireID() else {
            throw APIError.resourceOwnershipRequired
        }

        comment.content = request.content
        try await comment.save(on: req.db)

        return try await comment.toDTO(on: req, includeReplies: true)
    }

    func deleteComment(id: UUID, user: User, on req: Request) async throws {
        guard let comment = try await Comment.find(id, on: req.db) else {
            throw APIError.commentNotFound
        }

        guard try comment.$user.id == user.requireID() else {
            throw APIError.resourceOwnershipRequired
        }

        try await comment.delete(on: req.db)
    }

    func createReply(
        request: CommentRequest,
        articleID: UUID,
        parentID: UUID,
        user: User,
        on req: Request
    ) async throws -> CommentDTO {
        guard try await Comment.find(parentID, on: req.db) != nil else {
            throw APIError.commentNotFound
        }

        let reply = try Comment(
            content: request.content,
            articleID: articleID,
            userID: user.requireID(),
            parentID: parentID
        )
        try await reply.save(on: req.db)

        guard let savedReply = try await Comment.query(on: req.db)
            .filter(\.$id == reply.requireID())
            .with(\.$user)
            .first()
        else {
            throw APIError.databaseError
        }

        return try await savedReply.toDTO(on: req, includeReplies: true)
    }

    func getCommentReplies(
        parentID: UUID,
        pagination: PaginationRequest,
        on req: Request
    ) async throws -> PaginatedReplies {
        let query = Comment.query(on: req.db)
            .filter(\.$parent.$id == parentID)
            .with(\.$user)

        let totalItems = try await query.count()

        let replies = try await query
            .range(pagination.offset ..< (pagination.offset + pagination.validatedPerPage))
            .all()
            .asyncMap { try await $0.toDTO(on: req, includeReplies: true) }

        return PaginatedReplies(items: replies, totalItems: totalItems)
    }
}
