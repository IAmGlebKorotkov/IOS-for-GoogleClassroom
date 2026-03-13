

import Foundation
@testable import GoogleClassRoom

final class MockSolutionService: SolutionServiceProtocol {

    
    var submitError: Error?
    var deleteError: Error?
    var reviewError: Error?

    
    var stubSolutionId = UUID()
    var stubSolutionStatus: SolutionStatus = .pending
    var stubSolutions: [SolutionListItemDto] = []

    
    var submitCallCount = 0
    var deleteCallCount = 0
    var reviewCallCount = 0
    var lastReviewRequest: ReviewSolutionRequest?
    var lastSubmitRequest: SubmitSolutionRequest?

    func submitSolution(taskId: UUID, request: SubmitSolutionRequest) async throws -> ApiResponse<IdDto> {
        submitCallCount += 1
        lastSubmitRequest = request
        if let error = submitError { throw error }
        return ApiResponse(type: .success, message: nil, data: IdDto(id: stubSolutionId))
    }

    func deleteSolution(taskId: UUID) async throws -> ApiResponse<IdDto> {
        deleteCallCount += 1
        if let error = deleteError { throw error }
        return ApiResponse(type: .success, message: nil, data: IdDto(id: taskId))
    }

    func getSolution(taskId: UUID) async throws -> ApiResponse<StudentSolutionDetailsDto> {
        let solution = StudentSolutionDetailsDto(
            id: stubSolutionId,
            text: "My solution text",
            files: nil,
            score: nil,
            status: stubSolutionStatus,
            updatedDate: Date()
        )
        return ApiResponse(type: .success, message: nil, data: solution)
    }

    func getSolutions(taskId: UUID, skip: Int, take: Int, status: SolutionStatus?, studentId: UUID?) async throws -> ApiResponse<SolutionListDto> {
        let list = SolutionListDto(records: stubSolutions, totalRecords: stubSolutions.count)
        return ApiResponse(type: .success, message: nil, data: list)
    }

    func reviewSolution(solutionId: UUID, request: ReviewSolutionRequest) async throws -> ApiResponse<IdDto> {
        reviewCallCount += 1
        lastReviewRequest = request
        if let error = reviewError { throw error }
        return ApiResponse(type: .success, message: nil, data: IdDto(id: solutionId))
    }
}
