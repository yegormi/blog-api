import Foundation
import SotoCore

struct S3Configuration {
    let bucketName: String
    let region: Region
}

extension S3Configuration {
    var baseURL: String {
        "https://\(self.bucketName).s3.\(self.region.rawValue).amazonaws.com"
    }
}
