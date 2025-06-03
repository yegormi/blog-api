import Vapor
import VaporToOpenAPI

extension Link {
    enum ArticleID: LinkKey {
        static let description: String? = "Article identifier for accessing specific articles"
    }
}
