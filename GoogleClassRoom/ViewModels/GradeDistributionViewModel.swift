import Foundation
import Combine

@MainActor
final class GradeDistributionViewModel: ObservableObject {

    @Published var distribution: GradeDistributionResponseDto?
    @Published var editablePoints: [UUID: String] = [:]
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    let teamId: UUID
    let assignmentId: UUID
    let isCaptain: Bool

    private let service: GradeDistributionServiceProtocol

    init(
        teamId: UUID,
        assignmentId: UUID,
        isCaptain: Bool,
        service: GradeDistributionServiceProtocol? = nil
    ) {
        self.teamId = teamId
        self.assignmentId = assignmentId
        self.isCaptain = isCaptain
        self.service = service ?? ServiceLocator.shared.gradeDistributionService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await service.get(teamId: teamId, assignmentId: assignmentId)
            distribution = response.data
            if let dist = response.data {
                editablePoints = Dictionary(
                    uniqueKeysWithValues: dist.entries.map { ($0.userId, String(format: "%.1f", $0.points)) }
                )
            }
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() async {
        guard let dist = distribution else { return }
        let totalScore = dist.teamRawScore
        let entries = dist.entries.map { entry -> GradeDistributionEntryDto in
            let pts = Double(editablePoints[entry.userId] ?? "") ?? entry.points
            return GradeDistributionEntryDto(userId: entry.userId, points: pts)
        }
        let sum = entries.reduce(0.0) { $0 + $1.points }
        guard abs(sum - totalScore) < 0.01 else {
            errorMessage = "Сумма баллов (\(String(format: "%.1f", sum))) должна равняться общей оценке команды (\(String(format: "%.1f", totalScore)))"
            return
        }
        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }
        do {
            let response = try await service.update(teamId: teamId, assignmentId: assignmentId, entries: entries)
            distribution = response.data
            successMessage = "Распределение сохранено"
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func vote(_ voteType: GradeVoteType) async {
        do {
            try await service.vote(teamId: teamId, assignmentId: assignmentId, vote: voteType)
            successMessage = voteType == .for ? "Вы проголосовали «за»" : "Вы проголосовали «против»"
            await load()
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
