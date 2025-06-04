import Foundation

struct PaginatedResponse<T: Codable & Sendable>: Codable, Sendable {
    let items: [T]
    let totalItems: Int
}

typealias PaginatedArticles = PaginatedResponse<ArticleDTO>
typealias PaginatedComments = PaginatedResponse<CommentDTO>
typealias PaginatedReplies = PaginatedResponse<CommentDTO>
