

import Foundation

protocol SolutionServiceProtocol {
    func submitSolution(taskId: UUID, request: SubmitSolutionRequest) async throws -> ApiResponse<IdDto>
    func deleteSolution(taskId: UUID) async throws -> ApiResponse<IdDto>
    func getSolution(taskId: UUID) async throws -> ApiResponse<StudentSolutionDetailsDto>
    func getSolutions(taskId: UUID, skip: Int, take: Int, status: SolutionStatus?, studentId: UUID?) async throws -> ApiResponse<SolutionListDto>
    func reviewSolution(solutionId: UUID, request: ReviewSolutionRequest) async throws -> ApiResponse<IdDto>
}
