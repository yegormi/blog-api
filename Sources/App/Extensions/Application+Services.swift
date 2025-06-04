import Vapor

extension Application {
    private struct AuthServiceKey: StorageKey {
        typealias Value = any AuthServiceProtocol
    }
    
    private struct UserServiceKey: StorageKey {
        typealias Value = any UserServiceProtocol
    }
    
    private struct ArticleServiceKey: StorageKey {
        typealias Value = any ArticleServiceProtocol
    }
    
    private struct CommentServiceKey: StorageKey {
        typealias Value = any CommentServiceProtocol
    }
    
    var authService: any AuthServiceProtocol {
        get {
            storage[AuthServiceKey.self] ?? AuthService()
        }
        set {
            storage[AuthServiceKey.self] = newValue
        }
    }
    
    var userService: any UserServiceProtocol {
        get {
            storage[UserServiceKey.self] ?? UserService()
        }
        set {
            storage[UserServiceKey.self] = newValue
        }
    }
    
    var articleService: any ArticleServiceProtocol {
        get {
            storage[ArticleServiceKey.self] ?? ArticleService()
        }
        set {
            storage[ArticleServiceKey.self] = newValue
        }
    }
    
    var commentService: any CommentServiceProtocol {
        get {
            storage[CommentServiceKey.self] ?? CommentService()
        }
        set {
            storage[CommentServiceKey.self] = newValue
        }
    }
}