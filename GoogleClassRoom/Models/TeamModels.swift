import Foundation

enum TeamMemberRole: String, Codable {
    case member
    case leader
}

struct TeamMemberDto: Codable, Equatable {
    let userId: UUID
    let credentials: String
    let role: TeamMemberRole
}

struct TeamDto: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let members: [TeamMemberDto]
}

struct StudentTeamSolutionDetailsDto: Codable {
    let id: UUID?
    let text: String?
    let files: [FileDto]?
    let score: Int?
    let status: SolutionStatus
    let updatedDate: Date
    let team: TeamDto
    let submittedBy: UserCredentialsDto
}

struct TeamSolutionListItemDto: Codable, Identifiable {
    let id: UUID
    let team: TeamDto
    let text: String
    let score: Int?
    let status: SolutionStatus
    let files: [FileDto]?
    let updatedDate: Date
}

struct TeamSolutionListDto: Codable {
    let records: [TeamSolutionListItemDto]
    let totalRecords: Int
}

struct GradeDistributionEntryDto: Codable {
    let userId: UUID
    let points: Double
}

struct GradeDistributionResponseDto: Codable {
    let teamId: UUID
    let assignmentId: UUID
    let teamRawScore: Double
    let entries: [GradeDistributionEntryDto]
    let sumDistributed: Double
    let distributionChanged: Bool
}

enum GradeVoteType: String, Codable {
    case `for` = "for"
    case against
}
