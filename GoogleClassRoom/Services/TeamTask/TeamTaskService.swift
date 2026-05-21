import Foundation

private struct SubmitTeamSolutionDto: Encodable {
    let text: String?
    let files: [UUID]?
}

private struct ReviewTeamSolutionDto: Encodable {
    let score: Int?
    let status: SolutionStatus
    let comment: String?
    let evaluation: EvaluationDto?
}

private struct SubmitSelfAssessmentDto: Encodable {
    let evaluation: EvaluationDto
}

private struct CreateTeamRequestDto: Encodable {
    let name: String
}

private struct IgnoredResponseData: Codable {
    init() {}
    init(from decoder: Decoder) throws {}
    func encode(to encoder: Encoder) throws {}
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

    func createTeam(assignmentId: UUID, name: String) async throws -> ApiResponse<String?> {
        do {
            return try await createTeam(
                path: "/api/teacher/team-task/\(assignmentId.uuidString)/teams",
                name: name
            )
        } catch APIError.notFound {
            return try await createTeam(
                path: "/api/team-task/\(assignmentId.uuidString)/teams",
                name: name
            )
        } catch APIError.serverError(let message) where message.contains("405") {
            return try await createTeam(
                path: "/api/team-task/\(assignmentId.uuidString)/teams",
                name: name
            )
        }
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

    func submitSelfAssessment(taskId: UUID, evaluation: EvaluationDto) async throws -> ApiResponse<IdDto> {
        let body = SubmitSelfAssessmentDto(evaluation: evaluation)
        let response: ApiResponse<IdRequestDto> = try await client.request(
            path: "/api/team-task/\(taskId.uuidString)/self-assessment",
            method: .put,
            body: body
        )
        return ApiResponse(type: response.type, message: response.message, data: response.data.map { IdDto(id: $0.id) })
    }

    func deleteSelfAssessment(taskId: UUID) async throws -> ApiResponse<IdDto> {
        let response: ApiResponse<IdRequestDto> = try await client.request(
            path: "/api/team-task/\(taskId.uuidString)/self-assessment",
            method: .delete
        )
        return ApiResponse(type: response.type, message: response.message, data: response.data.map { IdDto(id: $0.id) })
    }

    func previewGrade(solutionId: UUID, evaluation: EvaluationDto) async throws -> ApiResponse<GradeBreakdownDto> {
        let body = GradePreviewRequestDto(evaluation: evaluation)
        return try await client.request(
            path: "/api/team-solution/\(solutionId.uuidString)/preview",
            method: .post,
            body: body
        )
    }

    func reviewSolution(solutionId: UUID, score: Int?, status: SolutionStatus, comment: String?, evaluation: EvaluationDto?) async throws -> ApiResponse<IdDto> {
        let body = ReviewTeamSolutionDto(score: score, status: status, comment: comment, evaluation: evaluation)
        let response: ApiResponse<IdRequestDto> = try await client.request(
            path: "/api/team-solution/\(solutionId.uuidString)/review",
            method: .post,
            body: body
        )
        return ApiResponse(type: response.type, message: response.message, data: response.data.map { IdDto(id: $0.id) })
    }

    private func createTeam(path: String, name: String) async throws -> ApiResponse<String?> {
        let body = CreateTeamRequestDto(name: name)
        let response: ApiResponse<IgnoredResponseData> = try await client.request(
            path: path,
            method: .post,
            body: body
        )
        return ApiResponse(type: response.type, message: response.message, data: nil)
    }
}
