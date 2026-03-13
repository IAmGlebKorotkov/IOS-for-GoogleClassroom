

import XCTest
@testable import GoogleClassRoom

@MainActor
final class AuthViewModelTests: XCTestCase {

    var mockAuth: MockAuthService!
    var sut: AuthViewModel!

    override func setUp() {
        super.setUp()
        mockAuth = MockAuthService()
        sut = AuthViewModel(auth: mockAuth)
    }

    override func tearDown() {
        sut = nil
        mockAuth = nil
        super.tearDown()
    }

    
    func test_register_withEmptyCredentials_setsErrorWithoutCallingService() async {
        await sut.register(email: "new@example.com", password: "password123", credentials: "  ")

        XCTAssertEqual(mockAuth.registerCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    
    func test_register_withInvalidEmail_setsErrorWithoutCallingService() async {
        await sut.register(email: "invalid", password: "password123", credentials: "Иван")

        XCTAssertEqual(mockAuth.registerCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    
    func test_register_withShortPassword_setsErrorWithoutCallingService() async {
        await sut.register(email: "new@example.com", password: "abc", credentials: "Иван")

        XCTAssertEqual(mockAuth.registerCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    

    
    func test_logout_callsServiceAndSetsIsLoggedInFalse() async {
        sut.isLoggedIn = true

        await sut.logout()

        XCTAssertFalse(sut.isLoggedIn)
        XCTAssertEqual(mockAuth.logoutCallCount, 1)
    }

    
    func test_logout_whenServiceThrows_stillSetsIsLoggedInFalse() async {
        sut.isLoggedIn = true
        mockAuth.logoutError = NetworkError.unauthorized

        await sut.logout()

        XCTAssertFalse(sut.isLoggedIn)
    }
}
