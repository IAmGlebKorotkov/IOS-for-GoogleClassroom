import Foundation

enum PostType: String, Codable, Hashable {
    case post
    case task
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
