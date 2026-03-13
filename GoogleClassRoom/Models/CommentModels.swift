import Foundation

struct CommentAuthorDto: Codable, Equatable {
    let id: UUID
    let credentials: String
}

struct CommentDto: Codable, Equatable {
    let id: UUID
    let text: String
    let isDeleted: Bool
    let author: CommentAuthorDto
    let nestedCount: Int
}

struct CommentListDto: Codable {
    let records: [CommentDto]
    let totalRecords: Int
}

struct AddCommentRequest: Codable {
    let text: String
}

struct EditCommentRequest: Codable {
    let text: String
}

struct CommentValidator {
    static func isValidText(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && trimmed.count <= 2000
    }
}
