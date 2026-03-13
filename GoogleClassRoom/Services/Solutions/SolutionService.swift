
import Foundation

private struct UpdateSolutionRequestDto: Encodable {
    let score: Int?
    let status: SolutionStatus
    let comment: String?
}

private struct SubmitSolutionRequestDto: Encodable {
    let text: String?
    let files: [UUID]?
}

private struct IdRequestDto: Codable {
    let id: UUID
}

final class SolutionService: SolutionServiceProtocol {
    private let client = APIClient.shared

    func submitSolution(taskId: UUID, request: SubmitSolutionRequest) async throws -> ApiResponse<IdDto> {
        let body = SubmitSolutionRequestDto(text: request.text, files: request.files)
        let response: ApiResponse<IdRequestDto> = try await client.request(
            path: "/api/task/\(taskId.uuidString)/solution",
            method: .put,
            body: body
        )
        let idDto = response.data.map { IdDto(id: $0.id) }
        return ApiResponse(type: response.type, message: response.message, data: idDto)
    }

    func deleteSolution(taskId: UUID) async throws -> ApiResponse<IdDto> {
        let response: ApiResponse<IdRequestDto> = try await client.request(
            path: "/api/task/\(taskId.uuidString)/solution",
            method: .delete
        )
        let idDto = response.data.map { IdDto(id: $0.id) }
        return ApiResponse(type: response.type, message: response.message, data: idDto)
    }

    func getSolution(taskId: UUID) async throws -> ApiResponse<StudentSolutionDetailsDto> {
        return try await client.request(path: "/api/task/\(taskId.uuidString)/solution")
    }

    func getSolutions(taskId: UUID, skip: Int, take: Int, status: SolutionStatus?, studentId: UUID?) async throws -> ApiResponse<SolutionListDto> {
        var queryItems = [
            URLQueryItem(name: "skip", value: "\(skip)"),
            URLQueryItem(name: "take", value: "\(take)")
        ]
        if let s = status { queryItems.append(URLQueryItem(name: "status", value: s.rawValue)) }
        if let id = studentId { queryItems.append(URLQueryItem(name: "studentId", value: id.uuidString)) }

        return try await client.request(
            path: "/api/task/\(taskId.uuidString)/solutions",
            queryItems: queryItems
        )
    }

    func reviewSolution(solutionId: UUID, request: ReviewSolutionRequest) async throws -> ApiResponse<IdDto> {
        let body = UpdateSolutionRequestDto(score: request.score, status: request.status, comment: request.comment)
        let response: ApiResponse<IdRequestDto> = try await client.request(
            path: "/api/solution/\(solutionId.uuidString)/review",
            method: .post,
            body: body
        )
        let idDto = response.data.map { IdDto(id: $0.id) }
        return ApiResponse(type: response.type, message: response.message, data: idDto)
    }
}
