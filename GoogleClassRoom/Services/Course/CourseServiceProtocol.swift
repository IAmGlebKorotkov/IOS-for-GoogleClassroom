import Foundation

protocol CourseServiceProtocol {
    func createCourse(title: String) async throws -> ApiResponse<CreateCourseResponse>
    func updateCourse(id: UUID, title: String) async throws -> ApiResponse<CreateCourseResponse>
    func getCourse(id: UUID) async throws -> ApiResponse<CourseDetailsDto>
    func joinCourse(inviteCode: String) async throws -> ApiResponse<JoinCourseResponse>
    func leaveCourse(id: UUID) async throws -> ApiResponse<String?>
    func getMembers(courseId: UUID, skip: Int, take: Int, query: String?) async throws -> ApiResponse<CourseMembersPagedResponse>
    func changeMemberRole(courseId: UUID, userId: UUID, role: UserRoleType) async throws -> ApiResponse<ChangeRoleResponse>
    func removeMember(courseId: UUID, userId: UUID) async throws -> ApiResponse<String?>
    func getUserCourses(skip: Int, take: Int) async throws -> ApiResponse<UserCoursesPagedResponse>
}
