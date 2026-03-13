
import Foundation

protocol UserServiceProtocol {
    func getCurrentUser() async throws -> ApiResponse<UserDto>
    func getUser(id: UUID) async throws -> ApiResponse<UserDto>
    func updateUser(credentials: String?, email: String?) async throws -> ApiResponse<String?>
    func searchUsers(query: String) async throws -> ApiResponse<[UserDto]>
}
