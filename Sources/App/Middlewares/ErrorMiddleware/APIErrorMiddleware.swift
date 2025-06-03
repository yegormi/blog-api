import Foundation
import NIOCore
import NIOHTTP1
import Vapor
import VaporToOpenAPI

/// Custom error middleware that uses APIErrorDTO for consistent error responses.
public final class APIErrorMiddleware: AsyncMiddleware {
    /// Create a default `APIErrorMiddleware`. Logs errors to a `Logger` based on `Environment`
    /// and converts `Error` to `Response` using `APIErrorDTO`.
    ///
    /// - parameters:
    ///     - environment: The environment to respect when presenting errors.
    public static func `default`(environment: Environment) -> APIErrorMiddleware {
        return .init { req, error in
            let status: HTTPStatus
            let message: String
            let source: ErrorSource
            var headers: HTTPHeaders = [:]
            
            /// Inspect the error type and extract what data we can.
            switch error {
            case let apiError as any APIErrorProtocol:
                /// If it's an APIError, use its status and message
                status = apiError.status
                message = apiError.message
                source = .capture()
                
            case let apiError as APIErrorDTO:
                /// If it's already an APIErrorDTO, use it directly
                status = apiError.status
                message = apiError.message
                source = .capture()
                
            case let debugAbort as (any DebuggableError & AbortError):
                status = debugAbort.status
                message = debugAbort.reason
                headers = debugAbort.headers
                source = debugAbort.source ?? .capture()
                
            case let abort as any AbortError:
                status = abort.status
                message = abort.reason
                headers = abort.headers
                source = .capture()
            
            case let debugErr as any DebuggableError:
                status = .internalServerError
                message = debugErr.reason
                source = debugErr.source ?? .capture()
            
            default:
                /// In debug mode, provide the error description; otherwise hide it to avoid sensitive data disclosure.
                status = .internalServerError
                message = environment.isRelease ? "Something went wrong." : String(describing: error)
                source = .capture()
            }
            
            /// Report the error
            req.logger.report(
                error: error,
                metadata: [
                    "method" : "\(req.method.rawValue)",
                    "url" : "\(req.url.string)",
                    "userAgent" : .array(req.headers["User-Agent"].map { "\($0)" })
                ],
                file: source.file,
                function: source.function,
                line: source.line
            )
            
            /// Create APIErrorDTO
            let apiErrorDTO = APIErrorDTO(
                status: status,
                error: status.reasonPhrase,
                message: message,
                path: req.url.path
            )
            
            /// Attempt to serialize the error to JSON
            let body: Response.Body
            do {
                let encoder = try ContentConfiguration.global.requireEncoder(for: .json)
                var byteBuffer = req.byteBufferAllocator.buffer(capacity: 0)
                try encoder.encode(apiErrorDTO, to: &byteBuffer, headers: &headers)
                
                body = .init(
                    buffer: byteBuffer,
                    byteBufferAllocator: req.byteBufferAllocator
                )
            } catch {
                body = .init(
                    string: "Oops: \(String(describing: error))\nWhile encoding error: \(message)",
                    byteBufferAllocator: req.byteBufferAllocator
                )
                headers.contentType = .plainText
            }
            
            /// Create a Response with appropriate status
            return Response(status: status, headers: headers, body: body)
        }
    }

    /// Error-handling closure.
    private let closure: @Sendable (Request, any Error) -> (Response)

    /// Create a new `APIErrorMiddleware`.
    ///
    /// - parameters:
    ///     - closure: Error-handling closure. Converts `Error` to `Response`.
    @preconcurrency public init(_ closure: @Sendable @escaping (Request, any Error) -> (Response)) {
        self.closure = closure
    }
    
    public func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        do {
            return try await next.respond(to: request)
        } catch {
            return self.closure(request, error)
        }
    }
}
