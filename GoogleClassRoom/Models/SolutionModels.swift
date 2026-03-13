import Foundation

enum SolutionStatus: String, Codable {
    case pending
    case checked
    case returned
}

struct SubmitSolutionRequest: Codable {
    let text: String?
    let files: [UUID]?
}

struct StudentSolutionDetailsDto: Codable {
    let id: UUID?
    let text: String?
    let files: [FileDto]?
    let score: Int?
    let status: SolutionStatus
    let updatedDate: Date
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
}

struct SolutionValidator {
    static func isScoreValid(_ score: Int, maxScore: Int) -> Bool {
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
