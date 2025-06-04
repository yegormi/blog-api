import Fluent
import Vapor

protocol UserServiceProtocol: Sendable {
    func uploadAvatar(user: User, file: FileUpload, on req: Request) async throws -> UserDTO
    func removeAvatar(user: User, on req: Request) async throws -> UserDTO
}

struct UserService: UserServiceProtocol, Sendable {
    func uploadAvatar(user: User, file: FileUpload, on req: Request) async throws -> UserDTO {
        guard let fileExtension = file.file.extension else {
            throw APIError.invalidFileFormat
        }

        let fileName = "\(UUID().uuidString.lowercased()).\(fileExtension)"
        let key = "avatars/\(fileName)"

        let userDTO = try await req.db.transaction { transaction in
            if let existingAvatar = try await user.$avatar.get(on: transaction) {
                try await req.fileStorage.deleteFile(key: existingAvatar.key)
                try await existingAvatar.delete(on: transaction)
            }

            _ = try await req.fileStorage.uploadFile(file.file, key: key)

            let avatar = try Avatar(key: key, originalFilename: file.file.filename, userID: user.requireID())
            try await user.$avatar.create(avatar, on: transaction)

            guard let userDB = try await User.query(on: transaction)
                .filter(\.$id == user.requireID())
                .with(\.$avatar)
                .first()
            else {
                throw APIError.userNotFound
            }

            return userDB.toDTO(on: req)
        }

        return userDTO
    }

    func removeAvatar(user: User, on req: Request) async throws -> UserDTO {
        let userDTO = try await req.db.transaction { transaction in
            guard let avatar = try await user.$avatar.get(on: transaction) else {
                throw APIError.avatarNotFound
            }
            try await req.fileStorage.deleteFile(key: avatar.key)
            try await avatar.delete(on: transaction)

            guard let userDB = try await User.query(on: transaction)
                .filter(\.$id == user.requireID())
                .with(\.$avatar)
                .first()
            else {
                throw APIError.userNotFound
            }

            return userDB.toDTO(on: req)
        }

        return userDTO
    }
}