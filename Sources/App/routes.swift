import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index")
    }

    try app.register(collection: ArticleController())
    try app.register(collection: AuthController())
    try app.register(collection: CommentController())
}
