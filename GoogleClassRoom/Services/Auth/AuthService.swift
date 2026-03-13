import Foundation

private struct RegisterRequestDto: Encodable {
    let email: String
    let password: String
    let credentials: String?
}

private struct LoginRequestDto: Encodable {
    let email: String
    let password: String
}

private struct ChangePasswordRequestDto: Encodable {
    let oldPassword: String
    let newPassword: String
}

final class AuthService: AuthServiceProtocol {
    private let client = APIClient.shared

    func register(email: String, password: String, credentials: String?) async throws -> ApiResponse<AuthResponseDto> {
        let body = RegisterRequestDto(email: email, password: password, credentials: credentials)
        let response: ApiResponse<AuthResponseDto> = try await client.request(
            path: "/api/auth/register",
            method: .post,
            body: body,
            requiresAuth: false
        )
        if let data = response.data {
            TokenStorage.shared.accessToken = data.accessToken
            TokenStorage.shared.refreshToken = data.refreshToken
        }
        return response
    }

    func login(email: String, password: String) async throws -> ApiResponse<AuthResponseDto> {
        let body = LoginRequestDto(email: email, password: password)
        let response: ApiResponse<AuthResponseDto> = try await client.request(
            path: "/api/auth/login",
            method: .post,
            body: body,
            requiresAuth: false
        )
        if let data = response.data {
            TokenStorage.shared.accessToken = data.accessToken
            TokenStorage.shared.refreshToken = data.refreshToken
        }
        return response
    }

    func logout() async throws -> ApiResponse<String?> {
        let response: ApiResponse<String?> = try await client.request(
            path: "/api/auth/logout",
            method: .post
        )
        TokenStorage.shared.clearAll()
        return response
    }

    func changePassword(oldPassword: String, newPassword: String) async throws -> ApiResponse<String?> {
        let body = ChangePasswordRequestDto(oldPassword: oldPassword, newPassword: newPassword)
        return try await client.request(
            path: "/api/auth/change-password",
            method: .post,
            body: body
        )
    }

    func refreshToken(token: String) async throws -> ApiResponse<IdDto> {
        return try await client.request(
            path: "/api/auth/refresh",
            method: .post,
            queryItems: [URLQueryItem(name: "token", value: token)],
            requiresAuth: false
        )
    }
}
