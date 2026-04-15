import Foundation
import Combine

@MainActor
final class CreatePostViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var errorMessage: String?
    @Published var uploadedFiles: [UploadedFileItem] = []

    let courseId: UUID
    private let service: PostServiceProtocol
    private let fileService: FileServiceProtocol

    init(courseId: UUID, service: PostServiceProtocol? = nil, fileService: FileServiceProtocol? = nil) {
        self.courseId = courseId
        self.service = service ?? ServiceLocator.shared.postService
        self.fileService = fileService ?? ServiceLocator.shared.fileService
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

    func createPost(
        type: PostType,
        title: String,
        text: String,
        deadline: Date?,
        maxScore: Int,
        taskType: TaskType,
        solvableAfterDeadline: Bool,
        minTeamSize: Int? = nil,
        maxTeamSize: Int? = nil,
        captainMode: CaptainSelectionMode? = nil,
        votingDurationHours: Int? = nil,
        predefinedTeamsCount: Int? = nil,
        allowJoinTeam: Bool? = nil,
        allowLeaveTeam: Bool? = nil,
        allowStudentTransferCaptain: Bool? = nil
    ) async -> Bool {
        guard PostValidator.isValidTitle(title) else {
            errorMessage = "Введите заголовок"
            return false
        }
        if type == .task || type == .teamTask {
            guard PostValidator.isValidMaxScore(maxScore) else {
                errorMessage = "Максимальный балл должен быть больше 0"
                return false
            }
            if let d = deadline {
                guard PostValidator.isDeadlineValid(d) else {
                    errorMessage = "Дедлайн должен быть в будущем"
                    return false
                }
            }
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fileIds = uploadedFiles.isEmpty ? nil : uploadedFiles.map { $0.id }
            let isTaskOrTeamTask = type == .task || type == .teamTask
            let request = CreatePostRequest(
                type: type,
                title: title,
                text: text.isEmpty ? nil : text,
                deadline: isTaskOrTeamTask ? deadline : nil,
                maxScore: isTaskOrTeamTask ? maxScore : nil,
                taskType: isTaskOrTeamTask ? taskType : nil,
                solvableAfterDeadline: isTaskOrTeamTask ? solvableAfterDeadline : nil,
                files: fileIds,
                minTeamSize: type == .teamTask ? minTeamSize : nil,
                maxTeamSize: type == .teamTask ? maxTeamSize : nil,
                captainMode: type == .teamTask ? captainMode : nil,
                votingDurationHours: type == .teamTask ? votingDurationHours : nil,
                predefinedTeamsCount: type == .teamTask ? predefinedTeamsCount : nil,
                allowJoinTeam: type == .teamTask ? allowJoinTeam : nil,
                allowLeaveTeam: type == .teamTask ? allowLeaveTeam : nil,
                allowStudentTransferCaptain: type == .teamTask ? allowStudentTransferCaptain : nil
            )
            _ = try await service.createPost(courseId: courseId, request: request)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
