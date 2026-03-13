

import Foundation
@testable import GoogleClassRoom

final class MockUserService: UserServiceProtocol {

    
    var getCurrentUserError: Error?
    var updateUserError: Error?

    
    var stubUser = UserDto(id: UUID(), credentials: "Иван Иванов", email: "ivan@example.com")

    
    var getCurrentUserCallCount = 0
    var updateUserCallCount = 0
    var lastUpdateCredentials: String?
    var lastUpdateEmail: String?

    func getCurrentUser() async throws -> ApiResponse<UserDto> {
        getCurrentUserCallCount += 1
        if let error = getCurrentUserError { throw error }
        return ApiResponse(type: .success, message: nil, data: stubUser)
    }

    func getUser(id: UUID) async throws -> ApiResponse<UserDto> {
        return ApiResponse(type: .success, message: nil, data: stubUser)
    }

    func updateUser(credentials: String?, email: String?) async throws -> ApiResponse<String?> {
        updateUserCallCount += 1
        lastUpdateCredentials = credentials
        lastUpdateEmail = email
        if let error = updateUserError { throw error }
        return ApiResponse(type: .success, message: nil, data: nil)
    }

    func searchUsers(query: String) async throws -> ApiResponse<[UserDto]> {
        return ApiResponse(type: .success, message: nil, data: [stubUser])
    }
}
