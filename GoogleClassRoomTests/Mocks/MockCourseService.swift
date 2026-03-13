

import Foundation
@testable import GoogleClassRoom

final class MockCourseService: CourseServiceProtocol {

    
    var createCourseError: Error?
    var joinCourseError: Error?
    var getCourseError: Error?
    var getMembersError: Error?
    var changeRoleError: Error?
    var removeMemberError: Error?

    
    var stubCourse = CourseDetailsDto(
        id: UUID(),
        title: "Test Course",
        role: .teacher,
        authorId: UUID(),
        inviteCode: "TEST123"
    )
    var stubJoinResponse = JoinCourseResponse(
        id: UUID(),
        title: "Joined Course",
        role: .student
    )
    var stubMembers = CourseMembersPagedResponse(records: [], totalRecords: 0)
    var stubUserCourses = UserCoursesPagedResponse(records: [], totalRecords: 0)

    
    var createCallCount = 0
    var joinCallCount = 0
    var leaveCallCount = 0
    var getMembersCallCount = 0
    var changeRoleCallCount = 0
    var removeMemberCallCount = 0
    var lastCreatedTitle: String?
    var lastJoinedCode: String?
    var lastChangedRole: UserRoleType?

    func createCourse(title: String) async throws -> ApiResponse<CreateCourseResponse> {
        createCallCount += 1
        lastCreatedTitle = title
        if let error = createCourseError { throw error }
        let response = CreateCourseResponse(id: stubCourse.id, title: title)
        return ApiResponse(type: .success, message: nil, data: response)
    }

    func updateCourse(id: UUID, title: String) async throws -> ApiResponse<CreateCourseResponse> {
        let response = CreateCourseResponse(id: id, title: title)
        return ApiResponse(type: .success, message: nil, data: response)
    }

    func getCourse(id: UUID) async throws -> ApiResponse<CourseDetailsDto> {
        if let error = getCourseError { throw error }
        return ApiResponse(type: .success, message: nil, data: stubCourse)
    }

    func joinCourse(inviteCode: String) async throws -> ApiResponse<JoinCourseResponse> {
        joinCallCount += 1
        lastJoinedCode = inviteCode
        if let error = joinCourseError { throw error }
        return ApiResponse(type: .success, message: nil, data: stubJoinResponse)
    }

    func leaveCourse(id: UUID) async throws -> ApiResponse<String?> {
        leaveCallCount += 1
        return ApiResponse(type: .success, message: nil, data: nil)
    }

    func getMembers(courseId: UUID, skip: Int, take: Int, query: String?) async throws -> ApiResponse<CourseMembersPagedResponse> {
        getMembersCallCount += 1
        if let error = getMembersError { throw error }
        return ApiResponse(type: .success, message: nil, data: stubMembers)
    }

    func changeMemberRole(courseId: UUID, userId: UUID, role: UserRoleType) async throws -> ApiResponse<ChangeRoleResponse> {
        changeRoleCallCount += 1
        lastChangedRole = role
        if let error = changeRoleError { throw error }
        return ApiResponse(type: .success, message: nil, data: ChangeRoleResponse(id: userId, role: role))
    }

    func removeMember(courseId: UUID, userId: UUID) async throws -> ApiResponse<String?> {
        removeMemberCallCount += 1
        if let error = removeMemberError { throw error }
        return ApiResponse(type: .success, message: nil, data: nil)
    }

    func getUserCourses(skip: Int, take: Int) async throws -> ApiResponse<UserCoursesPagedResponse> {
        return ApiResponse(type: .success, message: nil, data: stubUserCourses)
    }
}
