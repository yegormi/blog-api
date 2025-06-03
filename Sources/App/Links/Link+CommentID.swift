import Vapor
import VaporToOpenAPI

extension Link {
    enum CommentID: LinkKey {
        static let description: String? = "Comment identifier for accessing specific comments"
    }
}
