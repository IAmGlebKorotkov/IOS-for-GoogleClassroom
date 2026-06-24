

import Foundation
@testable import GoogleClassRoom

final class MockSolutionService: SolutionServiceProtocol {

    
    var submitError: Error?
    var deleteError: Error?
    var reviewError: Error?
    var previewError: Error?
    var selfAssessmentError: Error?

    
    var stubSolutionId = UUID()
    var stubSolutionStatus: SolutionStatus = .pending
    var stubSolutions: [SolutionListItemDto] = []

    
    var submitCallCount = 0
    var deleteCallCount = 0
    var reviewCallCount = 0
    var previewCallCount = 0
    var submitSelfAssessmentCallCount = 0
    var deleteSelfAssessmentCallCount = 0
    var lastReviewRequest: ReviewSolutionRequest?
    var lastSubmitRequest: SubmitSolutionRequest?
    var lastPreviewEvaluation: EvaluationDto?
    var lastSelfAssessmentEvaluation: EvaluationDto?

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

    func submitSelfAssessment(taskId: UUID, evaluation: EvaluationDto) async throws -> ApiResponse<IdDto> {
        submitSelfAssessmentCallCount += 1
        lastSelfAssessmentEvaluation = evaluation
        if let error = selfAssessmentError { throw error }
        return ApiResponse(type: .success, message: nil, data: IdDto(id: taskId))
    }

    func deleteSelfAssessment(taskId: UUID) async throws -> ApiResponse<IdDto> {
        deleteSelfAssessmentCallCount += 1
        if let error = selfAssessmentError { throw error }
        return ApiResponse(type: .success, message: nil, data: IdDto(id: taskId))
    }

    func previewGrade(solutionId: UUID, evaluation: EvaluationDto) async throws -> ApiResponse<GradeBreakdownDto> {
        previewCallCount += 1
        lastPreviewEvaluation = evaluation
        if let error = previewError { throw error }
        let finalScore = CriterionCalculator.estimatedScore(criteria: [], evaluation: evaluation)
        return ApiResponse(
            type: .success,
            message: nil,
            data: GradeBreakdownDto(
                baseTeacherScore: finalScore,
                baseStudentScore: nil,
                baseScore: finalScore,
                afterQualityCoefficient: finalScore,
                latePenalty: 0,
                afterLatePenalty: finalScore,
                afterBlocking: finalScore,
                finalScore: finalScore,
                expiredDays: 0,
                thresholdApplied: false,
                thresholdReason: nil
            )
        )
    }

    func reviewSolution(solutionId: UUID, request: ReviewSolutionRequest) async throws -> ApiResponse<IdDto> {
        reviewCallCount += 1
        lastReviewRequest = request
        if let error = reviewError { throw error }
        return ApiResponse(type: .success, message: nil, data: IdDto(id: solutionId))
    }

    func getNextPeerReview(taskId: UUID) async throws -> ApiResponse<PeerReviewTargetDto> {
        return ApiResponse(type: .success, message: nil, data: nil)
    }

    func submitPeerReview(reviewId: UUID, evaluation: EvaluationDto) async throws -> ApiResponse<PeerReviewProgressDto> {
        return ApiResponse(type: .success, message: nil, data: PeerReviewProgressDto(gradingMode: .peerToPeer, required: 1, completed: 1, canFinish: true, isCounted: true))
    }

    func getPeerReviewProgress(taskId: UUID) async throws -> ApiResponse<PeerReviewProgressDto> {
        return ApiResponse(type: .success, message: nil, data: PeerReviewProgressDto(gradingMode: .peerToPeer, required: 1, completed: 0, canFinish: false, isCounted: false))
    }

    func finishPeerReview(taskId: UUID) async throws -> ApiResponse<PeerReviewProgressDto> {
        return ApiResponse(type: .success, message: nil, data: PeerReviewProgressDto(gradingMode: .peerToPeer, required: 1, completed: 1, canFinish: true, isCounted: true))
    }
}
