import SotoS3
import Vapor

public protocol FileStorageService: Sendable {
    func uploadFile(_ file: File, key: String) async throws -> String
    func deleteFile(key: String) async throws
    func getFileURL(for key: String) -> String
}

struct S3Configuration {
    let bucketName: String
    let region: Region
}

extension S3Configuration {
    static let `default` = S3Configuration(
        bucketName: "storage-blog-api",
        region: .eunorth1
    )

    var baseUrl: String {
        "https://\(self.bucketName).s3.\(self.region.rawValue).amazonaws.com"
    }
}

public struct S3Service: FileStorageService {
    private let s3: S3
    private let config: S3Configuration

    init(client: AWSClient, config: S3Configuration = .default) {
        self.s3 = S3(client: client, region: config.region)
        self.config = config
    }

    public func uploadFile(_ file: File, key: String) async throws -> String {
        let multipartRequest = S3.CreateMultipartUploadRequest(
            bucket: self.config.bucketName,
            key: key
        )

        _ = try await self.s3.multipartUpload(multipartRequest, buffer: file.data)

        return self.getFileURL(for: key)
    }

    public func deleteFile(key: String) async throws {
        let deleteRequest = S3.DeleteObjectRequest(
            bucket: self.config.bucketName,
            key: key
        )

        _ = try await self.s3.deleteObject(deleteRequest)
    }

    public func getFileURL(for key: String) -> String {
        "\(self.config.baseUrl)/\(key)"
    }
}
