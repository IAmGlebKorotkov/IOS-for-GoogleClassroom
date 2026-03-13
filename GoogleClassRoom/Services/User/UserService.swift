
import Foundation

private struct UpdateUserRequestDto: Encodable {
    let credentials: String?
    let email: String?
}

final class UserService: UserServiceProtocol {
    private let client = APIClient.shared

    func getCurrentUser() async throws -> ApiResponse<UserDto> {
        return try await client.request(path: "/api/users")
    }

    func getUser(id: UUID) async throws -> ApiResponse<UserDto> {
        return try await client.request(path: "/api/users/\(id.uuidString)")
    }

    func updateUser(credentials: String?, email: String?) async throws -> ApiResponse<String?> {
        let body = UpdateUserRequestDto(credentials: credentials, email: email)
        return try await client.request(path: "/api/users", method: .put, body: body)
    }

    func searchUsers(query: String) async throws -> ApiResponse<[UserDto]> {
        let queryItems = [URLQueryItem(name: "query", value: query)]
        return try await client.request(path: "/api/users/search", queryItems: queryItems)
    }
}
