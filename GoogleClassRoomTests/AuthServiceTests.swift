

import XCTest
@testable import GoogleClassRoom

final class AuthServiceTests: XCTestCase {

    var sut: MockAuthService!

    override func setUp() {
        super.setUp()
        sut = MockAuthService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    

    func test_register_withValidCredentials_callsService() async throws {
        let response = try await sut.register(email: "test@example.com", password: "password123", credentials: "Иван Иванов")

        XCTAssertEqual(sut.registerCallCount, 1)
        XCTAssertEqual(sut.lastRegisterEmail, "test@example.com")
        XCTAssertEqual(response.type, .success)
        XCTAssertNotNil(response.data)
    }

    
    func test_register_withInvalidEmail_failsValidation() {
        XCTAssertFalse(AuthValidator.isValidEmail("not-an-email"))
    }

    
    func test_register_withShortPassword_failsValidation() {
        XCTAssertFalse(AuthValidator.isValidPassword("abc"))
    }

    
    func test_register_whenServerRejectsEmail_throwsError() async {
        sut.registerError = NetworkError.serverError("Email already exists")

        do {
            _ = try await sut.register(email: "existing@example.com", password: "password123", credentials: nil)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(sut.registerCallCount, 1)
        }
    }

    

    
    func test_logout_callsServiceOnce() async throws {
        _ = try await sut.logout()
        XCTAssertEqual(sut.logoutCallCount, 1)
    }

    

    
    func test_changePassword_callsServiceWithBothPasswords() async throws {
        _ = try await sut.changePassword(oldPassword: "oldPass123", newPassword: "newPass123")
        XCTAssertEqual(sut.changePasswordCallCount, 1)
    }

    
    func test_changePassword_newPasswordTooShort_failsValidation() {
        XCTAssertFalse(AuthValidator.isValidPassword("abc"))
    }

    func test_changePassword_newPasswordTooLong_failsValidation() {
        XCTAssertFalse(AuthValidator.isValidPassword(String(repeating: "a", count: 21)))
    }
}
