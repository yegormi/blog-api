import Vapor
import SwiftOpenAPI
import VaporToOpenAPI

@OpenAPIDescriptable
/// Request payload for file upload
struct FileUpload: Content, WithExample {
    /// File to be uploaded
    let file: File
    
    static let example = FileUpload(
        file: File(data: Data().base64EncodedString(), filename: "avatar.jpg")
    )
}
