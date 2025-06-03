import Vapor
import VaporToOpenAPI
import Yams

struct OpenAPIController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.get("swagger") { req in
            req.redirect(to: "swagger/", redirectType: .permanent)
        }
        .excludeFromOpenAPI()

        routes.get("swagger", "openapi.json") { req in
            req.application.routes.blogOpenAPI
        }
        .excludeFromOpenAPI()

        routes.get("swagger", "openapi.yaml") { req in
            try Response(
                status: .ok,
                body: Response.Body(
                    string: YAMLEncoder().encode(req.application.routes.blogOpenAPI)
                )
            )
        }
        .excludeFromOpenAPI()

        routes.stoplightDocumentation("stoplight", openAPIPath: "/swagger/openapi.json")
    }
}

extension Routes {
    var blogOpenAPI: OpenAPIObject {
        openAPI(
            info: InfoObject(
                title: "Blog API",
                description: "REST API for Blog",
                termsOfService: URL(string: "http://swagger.io/terms/"),
                contact: ContactObject(email: "apiteam@swagger.io"),
                license: LicenseObject(
                    name: "Apache 2.0",
                    url: URL(string: "http://www.apache.org/licenses/LICENSE-2.0.html")
                ),
                version: Version(1, 0, 0)
            ),
            externalDocs: ExternalDocumentationObject(
                description: "Find out more about Swagger",
                url: URL(string: "http://swagger.io")!
            )
        )
    }
}
