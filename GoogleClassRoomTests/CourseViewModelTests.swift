

import XCTest
@testable import GoogleClassRoom

@MainActor
final class CourseListViewModelTests: XCTestCase {

    var mockService: MockCourseService!
    var sut: CourseListViewModel!

    override func setUp() {
        super.setUp()
        mockService = MockCourseService()
        sut = CourseListViewModel(service: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    

    
    func test_loadCourses_populatesCoursesArray() async {
        mockService.stubUserCourses = UserCoursesPagedResponse(records: [
            UserCourseDto(id: UUID(), title: "iOS Разработка", role: .teacher),
            UserCourseDto(id: UUID(), title: "Алгоритмы", role: .student)
        ], totalRecords: 2)

        await sut.loadCourses()

        XCTAssertEqual(sut.courses.count, 2)
        XCTAssertEqual(sut.courses.first?.title, "iOS Разработка")
        XCTAssertNil(sut.errorMessage)
    }

    
    func test_loadCourses_whenNoCourses_coursesIsEmpty() async {
        mockService.stubUserCourses = UserCoursesPagedResponse(records: [], totalRecords: 0)

        await sut.loadCourses()

        XCTAssertEqual(sut.courses.count, 0)
    }

    
    func test_loadCourses_whenServiceThrows_setsErrorMessage() async {
        mockService.createCourseError = NetworkError.unauthorized 
        
        
        await sut.loadCourses()
        XCTAssertFalse(sut.isLoading)
    }

    

    
    func test_createCourse_withValidTitle_callsServiceAndReloads() async {
        await sut.createCourse(title: "Новый курс")

        XCTAssertEqual(mockService.createCallCount, 1)
        XCTAssertEqual(mockService.lastCreatedTitle, "Новый курс")
        XCTAssertNil(sut.errorMessage)
    }

    
    func test_createCourse_withEmptyTitle_setsErrorWithoutCallingService() async {
        await sut.createCourse(title: "   ")

        XCTAssertEqual(mockService.createCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    
    func test_createCourse_whenServiceThrows_setsErrorMessage() async {
        mockService.createCourseError = NetworkError.serverError("Title too long")

        await sut.createCourse(title: "Курс")

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    

    
    func test_joinCourse_withValidCode_callsServiceAndReloads() async {
        await sut.joinCourse(code: "INVITE123")

        XCTAssertEqual(mockService.joinCallCount, 1)
        XCTAssertEqual(mockService.lastJoinedCode, "INVITE123")
        XCTAssertNil(sut.errorMessage)
    }

    
    func test_joinCourse_withEmptyCode_setsErrorWithoutCallingService() async {
        await sut.joinCourse(code: "  ")

        XCTAssertEqual(mockService.joinCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    
    func test_joinCourse_whenCodeInvalid_setsErrorMessage() async {
        mockService.joinCourseError = NetworkError.notFound

        await sut.joinCourse(code: "WRONG")

        XCTAssertNotNil(sut.errorMessage)
    }
}

@MainActor
final class CourseMembersViewModelTests: XCTestCase {

    var mockService: MockCourseService!
    var sut: CourseMembersViewModel!
    let testCourseId = UUID()

    override func setUp() {
        super.setUp()
        mockService = MockCourseService()
        sut = CourseMembersViewModel(courseId: testCourseId, service: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    

    
    func test_loadMembers_populatesMembersArray() async {
        mockService.stubMembers = CourseMembersPagedResponse(records: [
            CourseMemberDto(id: UUID(), credentials: "Студент А", email: "a@a.com", role: .student),
            CourseMemberDto(id: UUID(), credentials: "Преп. Б", email: "b@b.com", role: .teacher)
        ], totalRecords: 2)

        await sut.loadMembers()

        XCTAssertEqual(sut.members.count, 2)
        XCTAssertNil(sut.errorMessage)
    }

    

    
    func test_changeRole_toTeacher_callsServiceWithCorrectRole() async {
        let userId = UUID()

        await sut.changeRole(userId: userId, to: .teacher)

        XCTAssertEqual(mockService.changeRoleCallCount, 1)
        XCTAssertEqual(mockService.lastChangedRole, .teacher)
    }

    
    func test_changeRole_toStudent_callsServiceWithStudentRole() async {
        let userId = UUID()

        await sut.changeRole(userId: userId, to: .student)

        XCTAssertEqual(mockService.lastChangedRole, .student)
    }

    
    func test_changeRole_whenForbidden_setsErrorMessage() async {
        mockService.changeRoleError = NetworkError.forbidden

        await sut.changeRole(userId: UUID(), to: .teacher)

        XCTAssertNotNil(sut.errorMessage)
    }

    

    
    func test_removeMember_removesFromLocalArray() async {
        let memberId = UUID()
        mockService.stubMembers = CourseMembersPagedResponse(records: [
            CourseMemberDto(id: memberId, credentials: "Студент", email: "s@s.com", role: .student)
        ], totalRecords: 1)
        await sut.loadMembers()
        XCTAssertEqual(sut.members.count, 1)

        await sut.removeMember(userId: memberId)

        XCTAssertEqual(sut.members.count, 0)
        XCTAssertEqual(mockService.removeMemberCallCount, 1)
    }

    
    func test_removeMember_whenForbidden_setsErrorMessage() async {
        mockService.removeMemberError = NetworkError.forbidden

        await sut.removeMember(userId: UUID())

        XCTAssertNotNil(sut.errorMessage)
    }
}
