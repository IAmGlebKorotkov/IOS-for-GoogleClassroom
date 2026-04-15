import Foundation
import Combine

@MainActor
final class TeamSolutionViewModel: ObservableObject {

    @Published var solution: StudentTeamSolutionDetailsDto?
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var uploadedFiles: [UploadedFileItem] = []
    @Published var isCaptain = false

    let taskId: UUID
    let maxScore: Int?

    private let service: TeamTaskServiceProtocol
    private let fileService: FileServiceProtocol
    private let teamService: TeamServiceProtocol

    init(
        taskId: UUID,
        maxScore: Int?,
        service: TeamTaskServiceProtocol? = nil,
        fileService: FileServiceProtocol? = nil,
        teamService: TeamServiceProtocol? = nil
    ) {
        self.taskId = taskId
        self.maxScore = maxScore
        self.service = service ?? ServiceLocator.shared.teamTaskService
        self.fileService = fileService ?? ServiceLocator.shared.fileService
        self.teamService = teamService ?? ServiceLocator.shared.teamService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await service.getSolution(taskId: taskId)
            solution = response.data
            if let teamId = response.data?.team.id {
                isCaptain = (try? await teamService.isCaptain(teamId: teamId)) ?? false
            }
        } catch let e as APIError where e == .notFound {
            solution = nil
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func uploadFile(data: Data, filename: String, mimeType: String) async {
        isUploading = true
        defer { isUploading = false }
        do {
            let response = try await fileService.uploadFile(data: data, filename: filename, mimeType: mimeType)
            if let id = response.data?.id {
                uploadedFiles.append(UploadedFileItem(id: id, name: filename))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeUploadedFile(id: UUID) {
        uploadedFiles.removeAll { $0.id == id }
    }

    func submit(text: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }
        do {
            let fileIds = uploadedFiles.isEmpty ? nil : uploadedFiles.map { $0.id }
            _ = try await service.submitSolution(
                taskId: taskId,
                text: text.isEmpty ? nil : text,
                files: fileIds
            )
            successMessage = "Командное решение отправлено"
            uploadedFiles = []
            await load()
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelSolution() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await service.deleteSolution(taskId: taskId)
            solution = nil
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var canSubmit: Bool {
        guard let status = solution?.status else { return true }
        return status == .returned
    }

    var canCancel: Bool {
        guard let status = solution?.status else { return false }
        return status == .pending
    }
}
