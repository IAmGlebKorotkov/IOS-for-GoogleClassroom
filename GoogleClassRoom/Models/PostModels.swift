import Foundation

enum PostType: String, Codable, Hashable {
    case post
    case task
    case teamTask = "teaM_TASK"
}

enum CaptainSelectionMode: String, Codable {
    case firstMember
    case teacherFixed
    case votingAndLottery
}

enum TaskType: String, Codable {
    case mandatory
    case optional
}

struct FileDto: Codable, Equatable {
    let id: String?
    let name: String?
}

struct CreatePostRequest: Codable {
    let type: PostType
    let title: String
    let text: String?
    let deadline: Date?
    let maxScore: Int?
    let taskType: TaskType?
    let solvableAfterDeadline: Bool?
    let files: [UUID]?
    // Team task fields
    let minTeamSize: Int?
    let maxTeamSize: Int?
    let captainMode: CaptainSelectionMode?
    let votingDurationHours: Int?
    let predefinedTeamsCount: Int?
    let allowJoinTeam: Bool?
    let allowLeaveTeam: Bool?
    let allowStudentTransferCaptain: Bool?
}

struct PostDetailsDto: Codable {
    let id: UUID?
    let type: PostType
    let title: String
    let text: String
    let deadline: Date?
    let maxScore: Int?
    let taskType: TaskType?
    let solvableAfterDeadline: Bool?
    let files: [FileDto]?
    let userSolution: UserSolutionDto?
}

struct UserSolutionDto: Codable {
    let id: UUID?
    let text: String
    let score: Int
    let status: SolutionStatus?
}

struct CourseFeedItemDto: Codable, Hashable {
    let id: UUID
    let type: PostType
    let title: String
    let createdDate: Date
}

struct FeedResponseDto: Codable {
    let records: [CourseFeedItemDto]?
    let totalRecords: Int
}

struct PostValidator {
    static func isValidTitle(_ title: String) -> Bool {
        return !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    static func isValidMaxScore(_ score: Int) -> Bool {
        return score > 0
    }

    static func isDeadlineValid(_ deadline: Date) -> Bool {
        return deadline > Date()
    }
}
