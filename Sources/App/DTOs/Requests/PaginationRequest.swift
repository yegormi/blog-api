import Vapor
import VaporToOpenAPI

/// Pagination request parameters
struct PaginationRequest: Content {
    /// Page number (1-based)
    let page: Int?
    /// Number of items per page
    let perPage: Int?

    /// Get validated page number (defaults to 1)
    var validatedPage: Int {
        max(self.page ?? 1, 1)
    }

    /// Get validated per page count (defaults to 10, max 100)
    var validatedPerPage: Int {
        let defaultPerPage = 10
        let maxPerPage = 100
        guard let perPage else { return defaultPerPage }
        return min(max(perPage, 1), maxPerPage)
    }

    /// Calculate offset for database queries
    var offset: Int {
        (self.validatedPage - 1) * self.validatedPerPage
    }
}

extension PaginationRequest: WithExample {
    static var example: PaginationRequest {
        PaginationRequest(page: 1, perPage: 10)
    }
}
