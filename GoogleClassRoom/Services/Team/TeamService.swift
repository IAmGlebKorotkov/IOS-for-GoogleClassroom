import Foundation

private struct VoteDto: Encodable {
    let vote: GradeVoteType
}

private struct BoolResponse: Decodable {
    let type: ApiResponseType
    let message: String?
    let data: Bool?
}

final class TeamService: TeamServiceProtocol {
    private let client = APIClient.shared

    func joinTeam(teamId: UUID) async throws -> ApiResponse<String?> {
        return try await client.request(
            path: "/api/teams/\(teamId.uuidString)/join",
            method: .post
        )
    }

    func leaveTeam(teamId: UUID) async throws -> ApiResponse<String?> {
        return try await client.request(
            path: "/api/teams/\(teamId.uuidString)/leave",
            method: .post
        )
    }

    func transferCaptain(teamId: UUID, toUserId: UUID) async throws -> ApiResponse<String?> {
        return try await client.request(
            path: "/api/teams/\(teamId.uuidString)/transfer-captain/\(toUserId.uuidString)",
            method: .post
        )
    }

    func startVoting(teamId: UUID) async throws -> ApiResponse<String?> {
        return try await client.request(
            path: "/api/teams/\(teamId.uuidString)/start-voting",
            method: .post
        )
    }

    func voteForCaptain(teamId: UUID, candidateId: UUID) async throws -> ApiResponse<String?> {
        return try await client.request(
            path: "/api/teams/\(teamId.uuidString)/vote/\(candidateId.uuidString)",
            method: .post
        )
    }

    func isCaptain(teamId: UUID) async throws -> Bool {
        let response: BoolResponse = try await client.request(
            path: "/api/teams/\(teamId.uuidString)/is-captain"
        )
        return response.data ?? false
    }

    func setFixedCaptain(teamId: UUID, userId: UUID) async throws -> ApiResponse<String?> {
        return try await client.request(
            path: "/api/teacher/teams/\(teamId.uuidString)/fixed-captain",
            method: .post,
            body: userId
        )
    }

    func renameTeam(teamId: UUID, newName: String) async throws -> ApiResponse<String?> {
        struct RenameDto: Encodable { let newName: String }
        return try await client.request(
            path: "/api/teacher/teams/\(teamId.uuidString)/rename",
            method: .put,
            body: RenameDto(newName: newName)
        )
    }

    func addStudent(teamId: UUID, studentId: UUID) async throws -> ApiResponse<String?> {
        return try await client.request(
            path: "/api/teacher/teams/\(teamId.uuidString)/add-student/\(studentId.uuidString)",
            method: .post
        )
    }

    func removeStudent(teamId: UUID, studentId: UUID) async throws -> ApiResponse<String?> {
        return try await client.request(
            path: "/api/teacher/teams/\(teamId.uuidString)/remove-student/\(studentId.uuidString)",
            method: .delete
        )
    }
}
