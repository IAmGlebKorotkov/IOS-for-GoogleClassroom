import Foundation
import Combine

struct UploadedFileItem: Identifiable {
    let id: UUID
    let name: String
}

@MainActor
final class SolutionViewModel: ObservableObject {

    @Published var solution: StudentSolutionDetailsDto?
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var uploadedFiles: [UploadedFileItem] = []

    let taskId: UUID
    let maxScore: Int?

    private let service: SolutionServiceProtocol
    private let fileService: FileServiceProtocol

    init(taskId: UUID, maxScore: Int?, service: SolutionServiceProtocol? = nil, fileService: FileServiceProtocol? = nil) {
        self.taskId = taskId
        self.maxScore = maxScore
        self.service = service ?? ServiceLocator.shared.solutionService
        self.fileService = fileService ?? ServiceLocator.shared.fileService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await service.getSolution(taskId: taskId)
            solution = response.data
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
            let request = SubmitSolutionRequest(text: text.isEmpty ? nil : text, files: fileIds)
            _ = try await service.submitSolution(taskId: taskId, request: request)
            successMessage = "Решение отправлено"
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
        SolutionValidator.canSubmit(status: solution?.status)
    }

    var canCancel: Bool {
        guard let status = solution?.status else { return false }
        return SolutionValidator.canCancel(status: status)
    }
}

extension APIError: Equatable {
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized, .unauthorized),
             (.forbidden, .forbidden),
             (.notFound, .notFound),
             (.invalidCredentials, .invalidCredentials),
             (.unknown, .unknown):
            return true
        case (.serverError(let a), .serverError(let b)):
            return a == b
        default:
            return false
        }
    }
}
