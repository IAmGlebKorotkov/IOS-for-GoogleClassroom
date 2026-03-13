

import Foundation
@testable import GoogleClassRoom

enum NetworkError: Error, LocalizedError {
    case unauthorized
    case forbidden
    case notFound
    case serverError(String)
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Unauthorized"
        case .forbidden: return "Forbidden"
        case .notFound: return "Not found"
        case .serverError(let msg): return msg
        case .invalidCredentials: return "Invalid email or password"
        }
    }
}

final class MockAuthService: AuthServiceProtocol {
    func refreshToken(token: String) async throws -> ApiResponse<IdDto> {
        refreshTokenCallCount += 1
        lastRefreshToken = token

        if let error = refreshTokenError {
            throw error
        }

        return ApiResponse(
            type: .success,
            message: nil,
            data: mockId
        )
    }

    
    
    var registerError: Error?
    var loginError: Error?
    var logoutError: Error?
    var changePasswordError: Error?
    var refreshTokenError: Error?

    
    var mockTokens = AuthResponseDto(
        accessToken: "mock-access-token",
        refreshToken: "mock-refresh-token"
    )
    var mockId = IdDto(id: UUID())

    
    var registerCallCount = 0
    var loginCallCount = 0
    var logoutCallCount = 0
    var changePasswordCallCount = 0
    var refreshTokenCallCount = 0

    var lastRegisterEmail: String?
    var lastRegisterPassword: String?
    var lastRegisterCredentials: String?
    var lastLoginEmail: String?
    var lastLoginPassword: String?
    var lastChangePasswordOld: String?
    var lastChangePasswordNew: String?
    var lastRefreshToken: String?

    

    func register(email: String, password: String, credentials: String?) async throws -> ApiResponse<AuthResponseDto> {
        registerCallCount += 1
        lastRegisterEmail = email
        lastRegisterPassword = password
        lastRegisterCredentials = credentials

        if let error = registerError {
            throw error
        }

        return ApiResponse(
            type: .success,
            message: nil,
            data: mockTokens
        )
    }

    func login(email: String, password: String) async throws -> ApiResponse<AuthResponseDto> {
        loginCallCount += 1
        lastLoginEmail = email
        lastLoginPassword = password

        if let error = loginError {
            throw error
        }

        
        if email == "test@example.com" && password == "password123" {
            return ApiResponse(
                type: .success,
                message: nil,
                data: mockTokens
            )
        } else if let error = loginError {
            throw error
        } else {
            throw NetworkError.invalidCredentials
        }
    }

    func logout() async throws -> ApiResponse<String?> {
        logoutCallCount += 1

        if let error = logoutError {
            throw error
        }

        return ApiResponse(
            type: .success,
            message: nil,
            data: nil
        )
    }

    func changePassword(oldPassword: String, newPassword: String) async throws -> ApiResponse<String?> {
        changePasswordCallCount += 1
        lastChangePasswordOld = oldPassword
        lastChangePasswordNew = newPassword

        if let error = changePasswordError {
            throw error
        }

        return ApiResponse(
            type: .success,
            message: nil,
            data: nil
        )
    }
}
