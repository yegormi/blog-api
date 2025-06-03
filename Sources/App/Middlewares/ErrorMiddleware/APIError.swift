import Vapor

/// Protocol for defining API errors with status and message
protocol APIErrorProtocol: Error {
    var status: HTTPStatus { get }
    var message: String { get }
}
