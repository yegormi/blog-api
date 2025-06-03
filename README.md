# BlogAPI

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Language](https://img.shields.io/badge/language-Swift-orange.svg)

## Overview
BlogAPI is a RESTful API designed for creating, reading, updating, and deleting blog posts. Built with scalability and security in mind, this API is perfect for anyone looking to implement blog functionality in their application. It includes user authentication, authorization, and various endpoints to manage blog content effectively.

## Features
- **User Authentication & Authorization**: Secure login and signup for users.
- **CRUD Operations**: Easily create, read, update, and delete blog posts.
- **Comments**: Enable comments on blog posts.
- **Pagination**: Efficiently manage large data sets with paginated responses.
- **Error Handling**: Comprehensive error messages for smooth debugging.

## Tech Stack
- **Swift**: Backend code written in Swift using the Vapor framework.
- **Database**: SQLite/PostgreSQL (configurable based on needs).
- **JWT**: Secure user authentication with JSON Web Tokens.

## Getting Started

### Prerequisites
- Swift 6 or later
- Vapor 4
- PostgreSQL (if using for production)

### Installation
1. Clone the repository:
    ```bash
    git clone https://github.com/yegormi/blog-api.git
    cd blog-api
    ```

2. Install dependencies:
    ```bash
    swift package update
    ```

3. Set up the environment variables as required in `.env.example`.

### Usage
1. Run the application:
    ```bash
    swift run
    ```
2. Access the API documentation at `http://localhost:8080/docs` for available endpoints and usage.

## API Endpoints
- **User Routes**
  - `POST /signup` - Register a new user.
  - `POST /login` - Authenticate an existing user.
- **Blog Routes**
  - `GET /blogs` - Get all blog posts.
  - `POST /blogs` - Create a new blog post.
  - `GET /blogs/{id}` - Get a single blog post by ID.
  - `PUT /blogs/{id}` - Update a blog post.
  - `DELETE /blogs/{id}` - Delete a blog post.
  
_For full endpoint details, refer to the API documentation._

## Testing
To run tests:
```bash
swift test
```

## License
This project is licensed under the MIT License.

## Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.
