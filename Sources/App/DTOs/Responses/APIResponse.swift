import SwiftOpenAPI
import Vapor
import VaporToOpenAPI

/// API Response wrapper for consistent response structure
@OpenAPIDescriptable
struct APIResponse<T: Codable & Sendable>: Content {
    /// HTTP status code of the response
    let status: Int
    /// Success indicator
    let success: Bool
    /// Optional message describing the response
    let message: String?
    /// The actual response data
    let data: T?
    /// API path that generated this response
    let path: String
    /// When the response was generated (ISO8601 format)
    let timestamp: String
    /// Optional metadata about the response
    let meta: ResponseMeta?

    init(
        status: HTTPStatus,
        success: Bool = true,
        message: String? = nil,
        data: T? = nil,
        path: String,
        meta: ResponseMeta? = nil
    ) {
        self.status = Int(status.code)
        self.success = success
        self.message = message
        self.data = data
        self.path = path
        self.timestamp = ISO8601DateFormatter().string(from: Date())
        self.meta = meta
    }
}

/// Response metadata for additional information
struct ResponseMeta: Codable, Sendable {
    /// Pagination information
    let pagination: PaginationMeta?
    /// API version
    let version: String?

    init(
        pagination: PaginationMeta? = nil,
        version: String? = nil
    ) {
        self.pagination = pagination
        self.version = version
    }
}

/// Pagination metadata
struct PaginationMeta: Codable, Sendable {
    /// Current page number
    let currentPage: Int
    /// Number of items per page
    let perPage: Int
    /// Total number of pages
    let totalPages: Int
    /// Total number of items
    let totalItems: Int
    /// Whether there's a next page
    let hasNext: Bool
    /// Whether there's a previous page
    let hasPrevious: Bool
}

// MARK: - Convenience Extensions

extension APIResponse {
    /// Create a successful response with data
    static func success<U: Codable>(
        data: U,
        message: String? = nil,
        path: String,
        meta: ResponseMeta? = nil
    ) -> APIResponse<U> {
        APIResponse<U>(
            status: .ok,
            success: true,
            message: message,
            data: data,
            path: path,
            meta: meta
        )
    }

    /// Create a successful response without data
    static func success(
        message: String? = nil,
        path: String,
        meta: ResponseMeta? = nil
    ) -> APIResponse<EmptyData> {
        APIResponse<EmptyData>(
            status: .ok,
            success: true,
            message: message,
            data: EmptyData(),
            path: path,
            meta: meta
        )
    }

    /// Create a created response with data
    static func created<U: Codable>(
        data: U,
        message: String? = "Resource created successfully",
        path: String,
        meta: ResponseMeta? = nil
    ) -> APIResponse<U> {
        APIResponse<U>(
            status: .created,
            success: true,
            message: message,
            data: data,
            path: path,
            meta: meta
        )
    }

    /// Create a no content response
    static func noContent(
        message: String? = "Operation completed successfully",
        path: String
    ) -> APIResponse<EmptyData> {
        APIResponse<EmptyData>(
            status: .noContent,
            success: true,
            message: message,
            data: EmptyData(),
            path: path
        )
    }
}

/// Empty data structure for responses without data
struct EmptyData: Codable, Sendable {}

// MARK: - WithExample Conformance

extension APIResponse: WithExample where T: WithExample {
    static var example: APIResponse<T> {
        APIResponse<T>(
            status: .ok,
            success: true,
            message: "Example response",
            data: T.example,
            path: "/api/example",
            meta: ResponseMeta.example
        )
    }
}

extension ResponseMeta: WithExample {
    static var example: ResponseMeta {
        ResponseMeta(
            pagination: PaginationMeta.example,
            version: "1.0.0"
        )
    }
}

extension PaginationMeta: WithExample {
    static var example: PaginationMeta {
        PaginationMeta(
            currentPage: 1,
            perPage: 10,
            totalPages: 10,
            totalItems: 100,
            hasNext: true,
            hasPrevious: false
        )
    }
}

extension EmptyData: WithExample {
    static var example: EmptyData {
        EmptyData()
    }
}

// MARK: - Array Response Helper

extension APIResponse where T: Collection, T.Element: Codable & Sendable {
    /// Create a successful response with array data and pagination
    static func successWithPagination(
        data: T,
        currentPage: Int,
        perPage: Int,
        totalItems: Int,
        message: String? = nil,
        path: String
    ) -> APIResponse<T> {
        let totalPages = Int(ceil(Double(totalItems) / Double(perPage)))
        let pagination = PaginationMeta(
            currentPage: currentPage,
            perPage: perPage,
            totalPages: totalPages,
            totalItems: totalItems,
            hasNext: currentPage < totalPages,
            hasPrevious: currentPage > 1
        )

        let meta = ResponseMeta(
            pagination: pagination
        )

        return APIResponse<T>(
            status: .ok,
            success: true,
            message: message,
            data: data,
            path: path,
            meta: meta
        )
    }
}
