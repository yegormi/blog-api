import Foundation
import VaporToOpenAPI

public extension AuthSchemeObject {
    static var blogAuth: AuthSchemeObject {
        .bearer(
            id: "blog_auth",
            format: "JWT",
            description: "JWT Bearer token authentication"
        )
    }
}
