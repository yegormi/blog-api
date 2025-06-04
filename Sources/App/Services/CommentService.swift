import Fluent
import Vapor

protocol CommentServiceProtocol: Sendable {
    func getArticleComments(articleID: UUID, pagination: PaginationRequest, on req: Request) async throws -> PaginatedComments
    func createComment(request: CommentRequest, articleID: UUID, user: User, on req: Request) async throws -> CommentDTO
    func getCommentById(id: UUID, on req: Request) async throws -> CommentDTO
    func updateComment(id: UUID, request: CommentRequest, user: User, on req: Request) async throws -> CommentDTO
    func deleteComment(id: UUID, user: User, on req: Request) async throws
}

struct CommentService: CommentServiceProtocol, Sendable {
    func getArticleComments(articleID: UUID, pagination: PaginationRequest, on req: Request) async throws -> PaginatedComments {
        let query = Comment.query(on: req.db)
            .filter(\.$article.$id == articleID)
            .with(\.$user)

        let totalItems = try await query.count()

        let comments = try await query
            .range(pagination.offset ..< (pagination.offset + pagination.validatedPerPage))
            .all()
            .map { $0.toDTO(on: req) }

        return PaginatedComments(items: comments, totalItems: totalItems)
    }

    func createComment(request: CommentRequest, articleID: UUID, user: User, on req: Request) async throws -> CommentDTO {
        let comment = try Comment(content: request.content, articleID: articleID, userID: user.requireID())
        try await comment.save(on: req.db)

        guard let savedComment = try await Comment.query(on: req.db)
            .filter(\.$id == comment.id!)
            .with(\.$user)
            .first() else {
            throw APIError.databaseError
        }

        return savedComment.toDTO(on: req)
    }

    func getCommentById(id: UUID, on req: Request) async throws -> CommentDTO {
        guard let comment = try await Comment.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$user)
            .first() else {
            throw APIError.commentNotFound
        }

        return comment.toDTO(on: req)
    }

    func updateComment(id: UUID, request: CommentRequest, user: User, on req: Request) async throws -> CommentDTO {
        guard let comment = try await Comment.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$user)
            .first() else {
            throw APIError.commentNotFound
        }
        
        guard try comment.$user.id == user.requireID() else {
            throw APIError.resourceOwnershipRequired
        }
        
        comment.content = request.content
        try await comment.save(on: req.db)

        return comment.toDTO(on: req)
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
}