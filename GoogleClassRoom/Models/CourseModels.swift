import Foundation

struct CourseDetailsDto: Codable, Equatable {
    let id: UUID
    let title: String
    let role: UserRoleType
    let authorId: UUID
    let inviteCode: String
}

struct CreateCourseRequest: Codable {
    let title: String
}

struct CreateCourseResponse: Codable {
    let id: UUID
    let title: String
}

struct JoinCourseRequest: Codable {
    let inviteCode: String
}

struct JoinCourseResponse: Codable {
    let id: UUID
    let title: String
    let role: UserRoleType
}

struct CourseMemberDto: Codable, Equatable {
    let id: UUID
    let credentials: String
    let email: String
    let role: UserRoleType
}

struct CourseMembersPagedResponse: Codable {
    let records: [CourseMemberDto]
    let totalRecords: Int
}

struct ChangeRoleRequest: Codable {
    let role: UserRoleType
}

struct ChangeRoleResponse: Codable {
    let id: UUID
    let role: UserRoleType
}

struct UserCourseDto: Codable, Hashable {
    let id: UUID
    let title: String?
    let role: UserRoleType?
}

struct UserCoursesPagedResponse: Codable {
    let records: [UserCourseDto]
    let totalRecords: Int
}
