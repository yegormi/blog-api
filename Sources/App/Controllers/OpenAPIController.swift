import Vapor
import VaporToOpenAPI

struct OpenAPIController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.get("swagger", "swagger.json") { req in
            req.application.routes.openAPI(
                info: InfoObject(
                    title: "Blog API",
                    description: "REST API for Blog",
                    termsOfService: URL(string: "http://swagger.io/terms/"),
                    contact: ContactObject(
                        email: "apiteam@swagger.io"
                    ),
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
        .excludeFromOpenAPI()

        routes.stoplightDocumentation(
            "stoplight",
            openAPIPath: "/swagger/swagger.json"
        )
    }
}
