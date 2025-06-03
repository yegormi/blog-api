import Vapor

public struct BucketStorageKey: StorageKey {
    public typealias Value = AWSClient
}

extension Application {
    var awsClient: AWSClient {
        get {
            guard let client = self.storage[BucketStorageKey.self] else {
                fatalError("AWSClient not setup. Use app.awsClient = ...")
            }
            return client
        }
        set {
            self.storage.set(BucketStorageKey.self, to: newValue) {
                try $0.syncShutdown()
            }
        }
    }
}
