import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index")
    }

    app.get("avatar") { req async throws in
        try await req.view.render("avatar")
    }

    try app.register(collection: ArticleController())
    try app.register(collection: AuthController())
    try app.register(collection: CommentController())
}
