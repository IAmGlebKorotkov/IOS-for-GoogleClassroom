

import XCTest
@testable import GoogleClassRoom

final class CourseServiceTests: XCTestCase {

    var sut: MockCourseService!

    override func setUp() {
        super.setUp()
        sut = MockCourseService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    

    
    func test_createCourse_returnsSuccessWithId() async throws {
        let response = try await sut.createCourse(title: "iOS Разработка")

        XCTAssertEqual(sut.createCallCount, 1)
        XCTAssertEqual(sut.lastCreatedTitle, "iOS Разработка")
        XCTAssertEqual(response.type, .success)
        XCTAssertNotNil(response.data?.id)
    }

    
    func test_createCourse_withEmptyTitle_shouldFail() async {
        sut.createCourseError = NetworkError.serverError("Title is required")

        do {
            _ = try await sut.createCourse(title: "")
            XCTFail("Expected error for empty title")
        } catch {
            XCTAssertEqual(sut.createCallCount, 1)
        }
    }

    func test_createCourse_withWhitespaceTitle_failsLocalValidation() {
        XCTAssertFalse(PostValidator.isValidTitle("   "))
    }

    

    
    func test_joinCourse_withValidCode_returnsStudentRole() async throws {
        sut.stubJoinResponse = JoinCourseResponse(id: UUID(), title: "Алгоритмы", role: .student)

        let response = try await sut.joinCourse(inviteCode: "INVITE123")

        XCTAssertEqual(sut.joinCallCount, 1)
        XCTAssertEqual(sut.lastJoinedCode, "INVITE123")
        XCTAssertEqual(response.data?.role, .student)
    }

    

    
    func test_leaveCourse_callsServiceOnce() async throws {
        let courseId = UUID()
        _ = try await sut.leaveCourse(id: courseId)
        XCTAssertEqual(sut.leaveCallCount, 1)
    }

    

    
    func test_getMembers_returnsPagedList() async throws {
        let student = CourseMemberDto(id: UUID(), credentials: "Студент А", email: "student@test.com", role: .student)
        let teacher = CourseMemberDto(id: UUID(), credentials: "Преподаватель Б", email: "teacher@test.com", role: .teacher)
        sut.stubMembers = CourseMembersPagedResponse(records: [student, teacher], totalRecords: 2)

        let response = try await sut.getMembers(courseId: UUID(), skip: 0, take: 10, query: nil)

        XCTAssertEqual(response.data?.totalRecords, 2)
        XCTAssertEqual(response.data?.records.count, 2)
    }

    
    func test_getMembers_withQuery_callsServiceWithQueryParam() async throws {
        _ = try await sut.getMembers(courseId: UUID(), skip: 0, take: 10, query: "Иван")
        XCTAssertEqual(sut.getMembersCallCount, 1)
    }

    

    
    func test_changeMemberRole_studentToTeacher_returnsTeacherRole() async throws {
        let userId = UUID()
        let response = try await sut.changeMemberRole(courseId: UUID(), userId: userId, role: .teacher)

        XCTAssertEqual(sut.changeRoleCallCount, 1)
        XCTAssertEqual(sut.lastChangedRole, .teacher)
        XCTAssertEqual(response.data?.role, .teacher)
    }

    
    func test_changeMemberRole_teacherToStudent_returnsStudentRole() async throws {
        let userId = UUID()
        let response = try await sut.changeMemberRole(courseId: UUID(), userId: userId, role: .student)

        XCTAssertEqual(response.data?.role, .student)
    }

    

    

    
    func test_getCourse_returnsCurrentUserRole() async throws {
        sut.stubCourse = CourseDetailsDto(
            id: UUID(),
            title: "Курс",
            role: .student,
            authorId: UUID(),
            inviteCode: "XYZ"
        )

        let response = try await sut.getCourse(id: UUID())
        XCTAssertEqual(response.data?.role, .student)
    }
}
