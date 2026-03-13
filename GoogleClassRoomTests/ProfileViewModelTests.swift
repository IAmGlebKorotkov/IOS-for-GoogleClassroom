

import XCTest
@testable import GoogleClassRoom

@MainActor
final class ProfileViewModelTests: XCTestCase {

    var mockUserService: MockUserService!
    var mockAuthService: MockAuthService!
    var sut: ProfileViewModel!

    override func setUp() {
        super.setUp()
        mockUserService = MockUserService()
        mockAuthService = MockAuthService()
        sut = ProfileViewModel(userService: mockUserService, authService: mockAuthService)
    }

    override func tearDown() {
        sut = nil
        mockUserService = nil
        mockAuthService = nil
        super.tearDown()
    }

    

    
    func test_loadProfile_populatesUser() async {
        mockUserService.stubUser = UserDto(id: UUID(), credentials: "Иван Иванов", email: "ivan@example.com")

        await sut.loadProfile()

        XCTAssertNotNil(sut.user)
        XCTAssertEqual(sut.user?.credentials, "Иван Иванов")
        XCTAssertEqual(sut.user?.email, "ivan@example.com")
        XCTAssertEqual(mockUserService.getCurrentUserCallCount, 1)
        XCTAssertNil(sut.errorMessage)
    }

    
    func test_loadProfile_whenUnauthorized_setsErrorMessage() async {
        mockUserService.getCurrentUserError = NetworkError.unauthorized

        await sut.loadProfile()

        XCTAssertNil(sut.user)
        XCTAssertNotNil(sut.errorMessage)
    }

    
    func test_loadProfile_completesAndResetsIsLoading() async {
        await sut.loadProfile()
        XCTAssertFalse(sut.isLoading)
    }

    

    
    func test_updateCredentials_withValidName_callsServiceAndReloads() async {
        await sut.updateCredentials("Новое Имя")

        XCTAssertEqual(mockUserService.updateUserCallCount, 1)
        XCTAssertEqual(mockUserService.lastUpdateCredentials, "Новое Имя")
        XCTAssertNotNil(sut.successMessage)
    }

    
    func test_updateCredentials_withEmptyName_setsErrorWithoutCallingService() async {
        await sut.updateCredentials("   ")

        XCTAssertEqual(mockUserService.updateUserCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    
    func test_updateCredentials_whenServiceThrows_setsErrorMessage() async {
        mockUserService.updateUserError = NetworkError.forbidden

        await sut.updateCredentials("Имя")

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertNil(sut.successMessage)
    }

    

    
    func test_changePassword_withValidPasswords_callsService() async {
        await sut.changePassword(old: "oldPass123", new: "newPass456")

        XCTAssertEqual(mockAuthService.changePasswordCallCount, 1)
        XCTAssertNotNil(sut.successMessage)
        XCTAssertNil(sut.errorMessage)
    }

    
    func test_changePassword_withShortNewPassword_setsValidationError() async {
        await sut.changePassword(old: "oldPass123", new: "abc")

        XCTAssertEqual(mockAuthService.changePasswordCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    
    func test_changePassword_withEmptyOldPassword_setsError() async {
        await sut.changePassword(old: "", new: "newPass123")

        XCTAssertEqual(mockAuthService.changePasswordCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    
    func test_changePassword_withTooLongNewPassword_setsError() async {
        await sut.changePassword(old: "oldPass123", new: String(repeating: "a", count: 21))

        XCTAssertEqual(mockAuthService.changePasswordCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    
    func test_changePassword_whenWrongOldPassword_setsErrorMessage() async {
        mockAuthService.changePasswordError = NetworkError.forbidden

        await sut.changePassword(old: "wrong", new: "newPass123")

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertNil(sut.successMessage)
    }
}
