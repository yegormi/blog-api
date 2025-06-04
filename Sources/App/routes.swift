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
    }
    .excludeFromOpenAPI()

    try app.register(collection: OpenAPIController())
    try app.register(
        collection: AuthController(
            authService: app.authService,
            userService: app.userService
        )
    )
    try app.register(
        collection: ArticleController(
            articleService: app.articleService
        )
    )
    try app.register(
        collection: CommentController(
            commentService: app.commentService
        )
    )
}
