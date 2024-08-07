import SotoS3
import Vapor

struct S3UploadService {
    let app: Application
    let req: Request
    let bucketName: String
    let region: Region

    init(
        _ app: Application,
        req: Request,
        bucketName: String = "storage-blog-api",
        region: Region = .eunorth1
    ) {
        self.req = req
        self.app = app
        self.bucketName = bucketName
        self.region = region
    }

    func uploadFile(_ file: File, key: String) async throws -> String? {
        let s3 = S3(client: self.app.awsClient, region: self.region)

        let multipartRequest = S3.CreateMultipartUploadRequest(bucket: self.bucketName, key: key)

        _ = try await s3.multipartUpload(multipartRequest, buffer: file.data)

        return "https://\(self.bucketName).s3.\(self.region.rawValue).amazonaws.com/\(key)"
    }
}
