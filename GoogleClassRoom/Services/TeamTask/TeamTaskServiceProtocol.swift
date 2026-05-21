import Foundation

protocol TeamTaskServiceProtocol {
    func getTeams(assignmentId: UUID) async throws -> ApiResponse<[TeamDto]>
    func getMyTeam(assignmentId: UUID) async throws -> ApiResponse<TeamDto>
    func getTeamsForTeacher(assignmentId: UUID) async throws -> ApiResponse<[TeamDto]>
    func createTeam(assignmentId: UUID, name: String) async throws -> ApiResponse<String?>
    func submitSolution(taskId: UUID, text: String?, files: [UUID]?) async throws -> ApiResponse<IdDto>
    func deleteSolution(taskId: UUID) async throws -> ApiResponse<IdDto>
    func getSolution(taskId: UUID) async throws -> ApiResponse<StudentTeamSolutionDetailsDto>
    func getSolutions(taskId: UUID, skip: Int, take: Int) async throws -> ApiResponse<TeamSolutionListDto>
    func submitSelfAssessment(taskId: UUID, evaluation: EvaluationDto) async throws -> ApiResponse<IdDto>
    func deleteSelfAssessment(taskId: UUID) async throws -> ApiResponse<IdDto>
    func previewGrade(solutionId: UUID, evaluation: EvaluationDto) async throws -> ApiResponse<GradeBreakdownDto>
    func reviewSolution(solutionId: UUID, score: Int?, status: SolutionStatus, comment: String?, evaluation: EvaluationDto?) async throws -> ApiResponse<IdDto>
}
