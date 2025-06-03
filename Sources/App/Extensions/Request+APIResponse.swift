import Vapor

extension Request {
    /// Create a successful API response with data
    func success<T: Codable & Sendable>(
        _ data: T,
        message: String? = nil,
        meta: ResponseMeta? = nil
    ) -> APIResponse<T> {
        APIResponse<T>.success(
            data: data,
            message: message,
            path: self.url.path,
            meta: meta
        )
    }
    
    /// Create a successful API response without data
    func success(
        message: String? = nil,
        meta: ResponseMeta? = nil
    ) -> APIResponse<EmptyData> {
        APIResponse<EmptyData>.success(
            message: message,
            path: self.url.path,
            meta: meta
        )
    }
    
    /// Create a created response with data
    func created<T: Codable & Sendable>(
        _ data: T,
        message: String? = "Resource created successfully",
        meta: ResponseMeta? = nil
    ) -> APIResponse<T> {
        APIResponse<T>.created(
            data: data,
            message: message,
            path: self.url.path,
            meta: meta
        )
    }
    
    /// Create a no content response
    func noContent(
        message: String? = "Operation completed successfully"
    ) -> APIResponse<EmptyData> {
        APIResponse<EmptyData>.noContent(
            message: message,
            path: self.url.path
        )
    }
    
    /// Create a paginated response
    func successWithPagination<T: Collection>(
        _ data: T,
        currentPage: Int,
        perPage: Int,
        totalItems: Int,
        message: String? = nil,
        processingTime: Double? = nil
    ) -> APIResponse<T> where T.Element: Codable & Sendable {
        APIResponse<T>.successWithPagination(
            data: data,
            currentPage: currentPage,
            perPage: perPage,
            totalItems: totalItems,
            message: message,
            path: self.url.path,
            processingTime: processingTime
        )
    }
}
