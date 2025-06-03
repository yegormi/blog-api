import Vapor
import VaporToOpenAPI

extension Link {
    enum UserToken: LinkKey {
        static let description: String? = "User authentication token for accessing protected resources"
    }

    enum UserID: LinkKey {
        static let description: String? = "User identifier for profile operations"
    }
}
