

import Foundation
import Combine

@MainActor
final class ReviewSolutionViewModel: ObservableObject {

    @Published var solutions: [SolutionListItemDto] = []
    @Published var isLoading = false
    @Published var isReviewing = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    let taskId: UUID
    let maxScore: Int?

    private let service: SolutionServiceProtocol

    init(taskId: UUID, maxScore: Int?, service: SolutionServiceProtocol? = nil) {
        self.taskId = taskId
        self.maxScore = maxScore
        self.service = service ?? ServiceLocator.shared.solutionService
    }

    func loadSolutions() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await service.getSolutions(
                taskId: taskId,
                skip: 0,
                take: 50,
                status: nil,
                studentId: nil
            )
            solutions = response.data?.records ?? []
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func review(solutionId: UUID, score: Int?, status: SolutionStatus, comment: String?) async {
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
            let request = ReviewSolutionRequest(score: score, status: status, comment: comment)
            _ = try await service.reviewSolution(solutionId: solutionId, request: request)
            successMessage = "Проверено"
            await loadSolutions()
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
