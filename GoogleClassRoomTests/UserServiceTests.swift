

import XCTest
@testable import GoogleClassRoom

final class UserServiceTests: XCTestCase {

    var sut: MockUserService!

    override func setUp() {
        super.setUp()
        sut = MockUserService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    

    
    func test_getCurrentUser_returnsUserData() async throws {
        sut.stubUser = UserDto(id: UUID(), credentials: "Мария Иванова", email: "maria@example.com")

        let response = try await sut.getCurrentUser()

        XCTAssertEqual(sut.getCurrentUserCallCount, 1)
        XCTAssertEqual(response.type, .success)
        XCTAssertEqual(response.data?.credentials, "Мария Иванова")
        XCTAssertEqual(response.data?.email, "maria@example.com")
    }

    
    func test_getCurrentUser_dataHasAllRequiredFields() async throws {
        let userId = UUID()
        sut.stubUser = UserDto(id: userId, credentials: "Тест Тестов", email: "test@test.com")

        let response = try await sut.getCurrentUser()

        XCTAssertNotNil(response.data?.id)
        XCTAssertEqual(response.data?.id, userId)
        XCTAssertFalse(response.data?.credentials.isEmpty ?? true)
        XCTAssertTrue(AuthValidator.isValidEmail(response.data?.email ?? ""))
    }

    

    
    func test_updateUser_withNewCredentials_callsService() async throws {
        _ = try await sut.updateUser(credentials: "Новое Имя", email: nil)

        XCTAssertEqual(sut.updateUserCallCount, 1)
        XCTAssertEqual(sut.lastUpdateCredentials, "Новое Имя")
        XCTAssertNil(sut.lastUpdateEmail)
    }

    
    func test_updateUser_withNewEmail_callsServiceWithEmail() async throws {
        _ = try await sut.updateUser(credentials: nil, email: "new@example.com")

        XCTAssertEqual(sut.updateUserCallCount, 1)
        XCTAssertNil(sut.lastUpdateCredentials)
        XCTAssertEqual(sut.lastUpdateEmail, "new@example.com")
    }

    
    func test_updateUser_withBothFields_passesBothToService() async throws {
        _ = try await sut.updateUser(credentials: "Иван", email: "ivan@new.com")

        XCTAssertEqual(sut.lastUpdateCredentials, "Иван")
        XCTAssertEqual(sut.lastUpdateEmail, "ivan@new.com")
    }
}
