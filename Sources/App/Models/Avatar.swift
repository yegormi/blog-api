import Fluent
import Foundation
import Vapor

final class Avatar: Model, @unchecked Sendable {
    static let schema = "avatars"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "key")
    var key: String

    @Field(key: "original_filename")
    var originalFilename: String

    @Parent(key: "user_id")
    var user: User

    @Timestamp(key: "created_at", on: .create, format: .iso8601)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update, format: .iso8601)
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, key: String, originalFilename: String, userID: User.IDValue) {
        self.id = id
        self.key = key
        self.originalFilename = originalFilename
        self.$user.id = userID
    }
}
