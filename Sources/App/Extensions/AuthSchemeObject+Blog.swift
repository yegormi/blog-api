import Foundation
import VaporToOpenAPI

public extension AuthSchemeObject {
    static var blogAuth: AuthSchemeObject {
        .bearer(
            id: "bearer",
            format: "JWT",
            description: "JWT Bearer token authentication"
        )
    }
}
