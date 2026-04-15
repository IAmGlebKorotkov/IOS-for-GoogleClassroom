import Foundation

final class GradeDistributionService: GradeDistributionServiceProtocol {
    private let client = APIClient.shared

    func get(teamId: UUID, assignmentId: UUID) async throws -> ApiResponse<GradeDistributionResponseDto> {
        return try await client.request(
            path: "/api/teams/\(teamId.uuidString)/assignments/\(assignmentId.uuidString)/grade-distribution"
        )
    }

    func update(teamId: UUID, assignmentId: UUID, entries: [GradeDistributionEntryDto]) async throws -> ApiResponse<GradeDistributionResponseDto> {
        struct UpdateDto: Encodable {
            let entries: [GradeDistributionEntryDto]
        }
        return try await client.request(
            path: "/api/teams/\(teamId.uuidString)/assignments/\(assignmentId.uuidString)/grade-distribution",
            method: .put,
            body: UpdateDto(entries: entries)
        )
    }

    func vote(teamId: UUID, assignmentId: UUID, vote: GradeVoteType) async throws {
        struct VoteDto: Encodable { let vote: GradeVoteType }
        let _: ApiResponse<String?> = try await client.request(
            path: "/api/teams/\(teamId.uuidString)/assignments/\(assignmentId.uuidString)/grade-distribution/vote",
            method: .post,
            body: VoteDto(vote: vote)
        )
    }
}
