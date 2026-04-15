import Foundation

protocol TeamServiceProtocol {
    func joinTeam(teamId: UUID) async throws -> ApiResponse<String?>
    func leaveTeam(teamId: UUID) async throws -> ApiResponse<String?>
    func transferCaptain(teamId: UUID, toUserId: UUID) async throws -> ApiResponse<String?>
    func startVoting(teamId: UUID) async throws -> ApiResponse<String?>
    func voteForCaptain(teamId: UUID, candidateId: UUID) async throws -> ApiResponse<String?>
    func isCaptain(teamId: UUID) async throws -> Bool
    // Teacher actions
    func setFixedCaptain(teamId: UUID, userId: UUID) async throws -> ApiResponse<String?>
    func renameTeam(teamId: UUID, newName: String) async throws -> ApiResponse<String?>
    func addStudent(teamId: UUID, studentId: UUID) async throws -> ApiResponse<String?>
    func removeStudent(teamId: UUID, studentId: UUID) async throws -> ApiResponse<String?>
}
