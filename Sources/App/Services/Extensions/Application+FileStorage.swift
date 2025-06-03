public struct FileStorageKey: StorageKey {
    public typealias Value = FileStorageService
}

extension Application {
    var fileStorage: any FileStorageService {
        get {
            guard let storage = storage[FileStorageKey.self] else {
                fatalError("FileStorage not configured. Use app.fileStorage = ...")
            }
            return storage
        }
        set {
            storage[FileStorageKey.self] = newValue
        }
    }
}

extension Request {
    var fileStorage: any FileStorageService {
        self.application.fileStorage
    }
}
