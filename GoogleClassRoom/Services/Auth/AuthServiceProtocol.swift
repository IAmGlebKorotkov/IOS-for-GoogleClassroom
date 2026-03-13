import Foundation

protocol AuthServiceProtocol {
    func register(email: String, password: String, credentials: String?) async throws -> ApiResponse<AuthResponseDto>
    func login(email: String, password: String) async throws -> ApiResponse<AuthResponseDto>
    func logout() async throws -> ApiResponse<String?>
    func changePassword(oldPassword: String, newPassword: String) async throws -> ApiResponse<String?>
    func refreshToken(token: String) async throws -> ApiResponse<IdDto>
}
