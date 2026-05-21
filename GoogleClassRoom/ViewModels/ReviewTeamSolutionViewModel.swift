import Foundation
import Combine

@MainActor
final class ReviewTeamSolutionViewModel: ObservableObject {

    @Published var solutions: [TeamSolutionListItemDto] = []
    @Published var isLoading = false
    @Published var isReviewing = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var previewBreakdown: GradeBreakdownDto?
    @Published var isPreviewing = false

    let taskId: UUID
    let maxScore: Int?
    let criteria: [CriterionDto]

    private let service: TeamTaskServiceProtocol

    init(taskId: UUID, maxScore: Int?, criteria: [CriterionDto] = [], service: TeamTaskServiceProtocol? = nil) {
        self.taskId = taskId
        self.maxScore = maxScore
        self.criteria = criteria.sorted { $0.orderIndex < $1.orderIndex }
        self.service = service ?? ServiceLocator.shared.teamTaskService
    }

    func loadSolutions() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await service.getSolutions(taskId: taskId, skip: 0, take: 50)
            solutions = response.data?.records ?? []
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func preview(solutionId: UUID, evaluation: EvaluationDto) async {
        guard !evaluation.isEmpty else {
            previewBreakdown = nil
            return
        }
        isPreviewing = true
        defer { isPreviewing = false }
        do {
            let response = try await service.previewGrade(solutionId: solutionId, evaluation: evaluation)
            previewBreakdown = response.data
        } catch {
            previewBreakdown = nil
        }
    }

    func review(solutionId: UUID, score: Int?, status: SolutionStatus, comment: String?, evaluation: EvaluationDto? = nil) async {
        if let score = score, let max = maxScore {
            guard SolutionValidator.isScoreValid(score, maxScore: max) else {
                errorMessage = "Оценка должна быть от 0 до \(max)"
                return
            }
        }
        isReviewing = true
        errorMessage = nil
        successMessage = nil
        defer { isReviewing = false }
        do {
            _ = try await service.reviewSolution(solutionId: solutionId, score: score, status: status, comment: comment, evaluation: evaluation)
            successMessage = "Проверено"
            await loadSolutions()
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
