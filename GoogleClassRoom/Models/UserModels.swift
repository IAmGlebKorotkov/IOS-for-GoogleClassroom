import Foundation

enum UserRoleType: String, Codable, Hashable {
    case student
    case teacher
}

struct UserDto: Codable, Equatable {
    let id: UUID
    let credentials: String
    let email: String
}

struct UserUpdateRequest: Codable {
    let credentials: String?
    let email: String?
}

struct UserCredentialsDto: Codable, Equatable {
    let id: UUID
    let credentials: String
}
