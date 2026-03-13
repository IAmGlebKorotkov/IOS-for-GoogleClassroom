import Foundation

private struct CreateCourseRequestDto: Encodable {
    let title: String
}

private struct ChangeRoleRequestDto: Encodable {
    let role: UserRoleType
}

private struct JoinCourseRequestDto: Encodable {
    let inviteCode: String
}

final class CourseService: CourseServiceProtocol {
    private let client = APIClient.shared

    func createCourse(title: String) async throws -> ApiResponse<CreateCourseResponse> {
        let body = CreateCourseRequestDto(title: title)
        let response: ApiResponse<CreateUpdateCourseResponseDto> = try await client.request(
            path: "/api/course",
            method: .post,
            body: body
        )
        let mapped = response.data.map { CreateCourseResponse(id: $0.id, title: $0.title) }
        return ApiResponse(type: response.type, message: response.message, data: mapped)
    }

    func updateCourse(id: UUID, title: String) async throws -> ApiResponse<CreateCourseResponse> {
        let body = CreateCourseRequestDto(title: title)
        let response: ApiResponse<CreateUpdateCourseResponseDto> = try await client.request(
            path: "/api/course/\(id.uuidString)",
            method: .put,
            body: body
        )
        let mapped = response.data.map { CreateCourseResponse(id: $0.id, title: $0.title) }
        return ApiResponse(type: response.type, message: response.message, data: mapped)
    }

    func getCourse(id: UUID) async throws -> ApiResponse<CourseDetailsDto> {
        return try await client.request(path: "/api/course/\(id.uuidString)")
    }

    func joinCourse(inviteCode: String) async throws -> ApiResponse<JoinCourseResponse> {
        let body = JoinCourseRequestDto(inviteCode: inviteCode)
        let response: ApiResponse<JoinCourseResponseDto> = try await client.request(
            path: "/api/course/join",
            method: .post,
            body: body
        )
        let mapped = response.data.map { JoinCourseResponse(id: $0.id, title: $0.title, role: $0.role) }
        return ApiResponse(type: response.type, message: response.message, data: mapped)
    }

    func leaveCourse(id: UUID) async throws -> ApiResponse<String?> {
        return try await client.request(
            path: "/api/course/\(id.uuidString)/leave",
            method: .delete
        )
    }

    func getMembers(courseId: UUID, skip: Int, take: Int, query: String?) async throws -> ApiResponse<CourseMembersPagedResponse> {
        var queryItems = [
            URLQueryItem(name: "skip", value: "\(skip)"),
            URLQueryItem(name: "take", value: "\(take)")
        ]
        if let q = query { queryItems.append(URLQueryItem(name: "query", value: q)) }

        let response: ApiResponse<CourseMemberDtoPagedResponseDto> = try await client.request(
            path: "/api/course/\(courseId.uuidString)/members",
            queryItems: queryItems
        )
        let mapped = response.data.map { dto in
            CourseMembersPagedResponse(records: dto.records, totalRecords: dto.totalRecords)
        }
        return ApiResponse(type: response.type, message: response.message, data: mapped)
    }

    func changeMemberRole(courseId: UUID, userId: UUID, role: UserRoleType) async throws -> ApiResponse<ChangeRoleResponse> {
        let body = ChangeRoleRequestDto(role: role)
        let response: ApiResponse<ChangeRoleResponseDto> = try await client.request(
            path: "/api/course/\(courseId.uuidString)/members/\(userId.uuidString)/role",
            method: .put,
            body: body
        )
        let mapped = response.data.map { ChangeRoleResponse(id: $0.id, role: $0.role) }
        return ApiResponse(type: response.type, message: response.message, data: mapped)
    }

    func removeMember(courseId: UUID, userId: UUID) async throws -> ApiResponse<String?> {
        return try await client.request(
            path: "/api/course/\(courseId.uuidString)/members/\(userId.uuidString)",
            method: .delete
        )
    }

    func getUserCourses(skip: Int, take: Int) async throws -> ApiResponse<UserCoursesPagedResponse> {
        let queryItems = [
            URLQueryItem(name: "skip", value: "\(skip)"),
            URLQueryItem(name: "take", value: "\(take)")
        ]
        let response: ApiResponse<UserCourseDtoPagedResponseDto> = try await client.request(
            path: "/api/user/courses",
            queryItems: queryItems
        )
        let mapped = response.data.map { dto in
            UserCoursesPagedResponse(records: dto.records, totalRecords: dto.totalRecords)
        }
        return ApiResponse(type: response.type, message: response.message, data: mapped)
    }
}

private struct CreateUpdateCourseResponseDto: Codable {
    let id: UUID
    let title: String
}

private struct JoinCourseResponseDto: Codable {
    let id: UUID
    let title: String
    let role: UserRoleType
}

private struct ChangeRoleResponseDto: Codable {
    let id: UUID
    let role: UserRoleType
}

private struct CourseMemberDtoPagedResponseDto: Codable {
    let records: [CourseMemberDto]
    let totalRecords: Int
}

private struct UserCourseDtoPagedResponseDto: Codable {
    let records: [UserCourseDto]
    let totalRecords: Int
}
