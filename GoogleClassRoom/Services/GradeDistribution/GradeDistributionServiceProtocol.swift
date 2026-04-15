import Foundation

protocol GradeDistributionServiceProtocol {
    func get(teamId: UUID, assignmentId: UUID) async throws -> ApiResponse<GradeDistributionResponseDto>
    func update(teamId: UUID, assignmentId: UUID, entries: [GradeDistributionEntryDto]) async throws -> ApiResponse<GradeDistributionResponseDto>
    func vote(teamId: UUID, assignmentId: UUID, vote: GradeVoteType) async throws
}
