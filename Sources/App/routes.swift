import Fluent
import Vapor
import VaporToOpenAPI

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index")
    }
    .excludeFromOpenAPI()

    app.get("avatar") { req async throws in
        try await req.view.render("avatar")
    app.get("avatar") { req async throws in
        try await req.view.render("avatar")
    }
    .excludeFromOpenAPI()

    try app.register(collection: OpenAPIController())
    try app.register(collection: AuthController())
    try app.register(collection: ArticleController())
    try app.register(collection: CommentController())
}
