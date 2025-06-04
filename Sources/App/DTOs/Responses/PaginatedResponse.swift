import Foundation

struct PaginatedResponse<T: Codable & Sendable>: Codable, Sendable {
    let items: [T]
    let totalItems: Int
    
    init(items: [T], totalItems: Int) {
        self.items = items
        self.totalItems = totalItems
    }
}

typealias PaginatedArticles = PaginatedResponse<ArticleDTO>
typealias PaginatedComments = PaginatedResponse<CommentDTO>
