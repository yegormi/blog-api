import Vapor

enum APIError: AbortError {
    case articleNotFound
    case userNotFound
    case invalidCredentials

    var reason: String {
        switch self {
        case .articleNotFound:
            "The requested article was not found."
        case .userNotFound:
            "The requested user was not found."
        case .invalidCredentials:
            "Invalid username or password."
        }
    }

    var status: HTTPStatus {
        switch self {
        case .articleNotFound, .userNotFound:
            .notFound
        case .invalidCredentials:
            .unauthorized
        }
    }
}
