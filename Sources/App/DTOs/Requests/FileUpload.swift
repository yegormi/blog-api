import SwiftOpenAPI
import Vapor
import VaporToOpenAPI

/// Request payload for file upload
@OpenAPIDescriptable
struct FileUpload: Content, WithExample {
    /// File to be uploaded
    let file: File

    static let example = FileUpload(
        file: File(data: Data().base64EncodedString(), filename: "avatar.jpg")
    )
}
