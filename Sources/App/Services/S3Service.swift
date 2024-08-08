import SotoS3
import Vapor

public protocol FileStorageService: Sendable {
    func uploadFile(_ file: File, key: String) async throws -> String
    func deleteFile(key: String) async throws
    func getFileURL(for key: String) -> String
}

public struct S3Service: FileStorageService {
    private let s3: S3
    private let config: S3Configuration

    init(client: AWSClient, config: S3Configuration) {
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
        "\(self.config.baseURL)/\(key)"
    }
}
