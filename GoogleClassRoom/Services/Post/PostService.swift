import Foundation

final class PostService: PostServiceProtocol {
    private let client = APIClient.shared

    func createPost(courseId: UUID, request: CreatePostRequest) async throws -> ApiResponse<IdDto> {
        let body = CreateUpdatePostDto(
            type: request.type,
            title: request.title,
            text: request.text,
            deadline: request.deadline,
            maxScore: request.maxScore,
            taskType: request.taskType,
            solvableAfterDeadline: request.solvableAfterDeadline,
            files: request.files,
            minTeamSize: request.minTeamSize,
            maxTeamSize: request.maxTeamSize,
            captainMode: request.captainMode,
            votingDurationHours: request.votingDurationHours,
            predefinedTeamsCount: request.predefinedTeamsCount,
            allowJoinTeam: request.allowJoinTeam,
            allowLeaveTeam: request.allowLeaveTeam,
            allowStudentTransferCaptain: request.allowStudentTransferCaptain
        )
        let response: ApiResponse<IdRequestDto> = try await client.request(
            path: "/api/course/\(courseId.uuidString)/task",
            method: .post,
            body: body
        )
        let idDto = response.data.map { IdDto(id: $0.id) }
        return ApiResponse(type: response.type, message: response.message, data: idDto)
    }

    func getPost(id: UUID) async throws -> ApiResponse<PostDetailsDto> {
        return try await client.request(path: "/api/post/\(id.uuidString)")
    }

    func updatePost(id: UUID, request: CreatePostRequest) async throws -> ApiResponse<IdDto> {
        let body = CreateUpdatePostDto(
            type: request.type,
            title: request.title,
            text: request.text,
            deadline: request.deadline,
            maxScore: request.maxScore,
            taskType: request.taskType,
            solvableAfterDeadline: request.solvableAfterDeadline,
            files: request.files,
            minTeamSize: request.minTeamSize,
            maxTeamSize: request.maxTeamSize,
            captainMode: request.captainMode,
            votingDurationHours: request.votingDurationHours,
            predefinedTeamsCount: request.predefinedTeamsCount,
            allowJoinTeam: request.allowJoinTeam,
            allowLeaveTeam: request.allowLeaveTeam,
            allowStudentTransferCaptain: request.allowStudentTransferCaptain
        )
        let response: ApiResponse<IdRequestDto> = try await client.request(
            path: "/api/post/\(id.uuidString)",
            method: .put,
            body: body
        )
        let idDto = response.data.map { IdDto(id: $0.id) }
        return ApiResponse(type: response.type, message: response.message, data: idDto)
    }

    func deletePost(id: UUID) async throws -> ApiResponse<IdDto> {
        let response: ApiResponse<IdRequestDto> = try await client.request(
            path: "/api/post/\(id.uuidString)",
            method: .delete
        )
        let idDto = response.data.map { IdDto(id: $0.id) }
        return ApiResponse(type: response.type, message: response.message, data: idDto)
    }

    func getFeed(courseId: UUID, skip: Int, take: Int) async throws -> ApiResponse<FeedResponseDto> {
        let queryItems = [
            URLQueryItem(name: "skip", value: "\(skip)"),
            URLQueryItem(name: "take", value: "\(take)")
        ]
        return try await client.request(
            path: "/api/course/\(courseId.uuidString)/feed",
            queryItems: queryItems
        )
    }
}

private struct IdRequestDto: Codable {
    let id: UUID
}

private struct CreateUpdatePostDto: Encodable {
    let type: PostType
    let title: String
    let text: String?
    let deadline: Date?
    let maxScore: Int?
    let taskType: TaskType?
    let solvableAfterDeadline: Bool?
    let files: [UUID]?
    let minTeamSize: Int?
    let maxTeamSize: Int?
    let captainMode: CaptainSelectionMode?
    let votingDurationHours: Int?
    let predefinedTeamsCount: Int?
    let allowJoinTeam: Bool?
    let allowLeaveTeam: Bool?
    let allowStudentTransferCaptain: Bool?
}
