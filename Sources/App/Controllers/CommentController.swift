import Fluent
import Vapor

struct CommentController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let comments = routes
            .grouped("articles", ":articleID", "comments")
            .grouped(JWTMiddleware())

        comments.get(use: self.index)
        comments.post(use: self.create)
        comments.group(":commentID") { comment in
            comment.get(use: self.show)
            comment.put(use: self.update)
            comment.delete(use: self.delete)
        }
    }

    @Sendable
    func index(req: Request) async throws -> [CommentDTO] {
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
    func create(req: Request) async throws -> CommentDTO {
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
    func show(req: Request) async throws -> CommentDTO {
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
    func update(req: Request) async throws -> CommentDTO {
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
    func delete(req: Request) async throws -> HTTPStatus {
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
