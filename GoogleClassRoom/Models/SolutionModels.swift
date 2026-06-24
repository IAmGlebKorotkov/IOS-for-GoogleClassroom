import Foundation

enum SolutionStatus: String, Codable {
    case pending
    case checked
    case returned
}

struct SubmitSolutionRequest: Codable {
    let text: String?
    let files: [UUID]?
    var selfAssessment: EvaluationDto? = nil
}

struct StudentSolutionDetailsDto: Codable {
    let id: UUID?
    let text: String?
    let files: [FileDto]?
    let score: Int?
    let status: SolutionStatus
    let updatedDate: Date
    var selfAssessment: EvaluationDto? = nil
    var teacherEvaluation: EvaluationDto? = nil
    var breakdown: GradeBreakdownDto? = nil
    var peerReviewProgress: PeerReviewProgressDto? = nil
}

struct SolutionListItemDto: Codable {
    let id: UUID
    let user: UserCredentialsDto
    let text: String
    let score: Int?
    let status: SolutionStatus
    let files: [FileDto]?
    let updatedDate: Date
}

struct SolutionListDto: Codable {
    let records: [SolutionListItemDto]
    let totalRecords: Int
}

struct ReviewSolutionRequest: Codable {
    let score: Int?
    let status: SolutionStatus
    let comment: String?
    var evaluation: EvaluationDto? = nil
}

struct AnonymizedSolutionDto: Codable, Hashable {
    let text: String?
    let files: [FileDto]?
}

struct PeerReviewTargetDto: Codable, Hashable {
    let reviewId: UUID
    let taskId: UUID
    let solution: AnonymizedSolutionDto?
    let criteria: [CriterionDto]?
    let assignedAt: Date
}

struct PeerReviewProgressDto: Codable, Hashable {
    let gradingMode: GradingMode?
    let required: Int
    let completed: Int
    let canFinish: Bool
    let isCounted: Bool
}

struct SubmitPeerReviewDto: Codable {
    let evaluation: EvaluationDto
}

struct SolutionValidator {
    static func isScoreValid(_ score: Int, maxScore: Int) -> Bool {
        return score >= 0 && score <= maxScore
    }

    static func isScoreValid(_ score: Double, maxScore: Double) -> Bool {
        return score >= 0 && score <= maxScore
    }

    static func canSubmit(status: SolutionStatus?) -> Bool {
        guard let status = status else { return true }
        return status == .returned
    }

    static func canCancel(status: SolutionStatus) -> Bool {
        return status == .pending
    }
}
