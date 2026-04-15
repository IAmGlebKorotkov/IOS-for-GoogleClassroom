import Foundation

private struct SubmitTeamSolutionDto: Encodable {
    let text: String?
    let files: [UUID]?
}

private struct ReviewTeamSolutionDto: Encodable {
    let score: Int?
    let status: SolutionStatus
    let comment: String?
}

private struct IdRequestDto: Codable {
    let id: UUID
}

final class TeamTaskService: TeamTaskServiceProtocol {
    private let client = APIClient.shared

    func getTeams(assignmentId: UUID) async throws -> ApiResponse<[TeamDto]> {
        return try await client.request(
            path: "/api/team-task/\(assignmentId.uuidString)/teams"
        )
    }

    func getMyTeam(assignmentId: UUID) async throws -> ApiResponse<TeamDto> {
        return try await client.request(
            path: "/api/team-task/\(assignmentId.uuidString)/my-team"
        )
    }

    func getTeamsForTeacher(assignmentId: UUID) async throws -> ApiResponse<[TeamDto]> {
        return try await client.request(
            path: "/api/teacher/team-task/\(assignmentId.uuidString)/teams"
        )
    }

    func submitSolution(taskId: UUID, text: String?, files: [UUID]?) async throws -> ApiResponse<IdDto> {
        let body = SubmitTeamSolutionDto(text: text, files: files)
        let response: ApiResponse<IdRequestDto> = try await client.request(
            path: "/api/team-task/\(taskId.uuidString)/solution",
            method: .put,
            body: body
        )
        return ApiResponse(type: response.type, message: response.message, data: response.data.map { IdDto(id: $0.id) })
    }

    func deleteSolution(taskId: UUID) async throws -> ApiResponse<IdDto> {
        let response: ApiResponse<IdRequestDto> = try await client.request(
            path: "/api/team-task/\(taskId.uuidString)/solution",
            method: .delete
        )
        return ApiResponse(type: response.type, message: response.message, data: response.data.map { IdDto(id: $0.id) })
    }

    func getSolution(taskId: UUID) async throws -> ApiResponse<StudentTeamSolutionDetailsDto> {
        return try await client.request(
            path: "/api/team-task/\(taskId.uuidString)/solution"
        )
    }

    func getSolutions(taskId: UUID, skip: Int, take: Int) async throws -> ApiResponse<TeamSolutionListDto> {
        let queryItems = [
            URLQueryItem(name: "skip", value: "\(skip)"),
            URLQueryItem(name: "take", value: "\(take)")
        ]
        return try await client.request(
            path: "/api/team-task/\(taskId.uuidString)/solutions",
            queryItems: queryItems
        )
    }

    func reviewSolution(solutionId: UUID, score: Int?, status: SolutionStatus, comment: String?) async throws -> ApiResponse<IdDto> {
        let body = ReviewTeamSolutionDto(score: score, status: status, comment: comment)
        let response: ApiResponse<IdRequestDto> = try await client.request(
            path: "/api/team-solution/\(solutionId.uuidString)/review",
            method: .post,
            body: body
        )
        return ApiResponse(type: response.type, message: response.message, data: response.data.map { IdDto(id: $0.id) })
    }
}
