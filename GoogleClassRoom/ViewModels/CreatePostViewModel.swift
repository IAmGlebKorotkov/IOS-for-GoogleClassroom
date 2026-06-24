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

    init(
        courseId: UUID,
        service: PostServiceProtocol? = nil,
        fileService: FileServiceProtocol? = nil,
        uploadedFiles: [UploadedFileItem] = []
    ) {
        self.courseId = courseId
        self.service = service ?? ServiceLocator.shared.postService
        self.fileService = fileService ?? ServiceLocator.shared.fileService
        self.uploadedFiles = uploadedFiles
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
        allowStudentTransferCaptain: Bool? = nil,
        failThreshold: Double? = nil,
        successThreshold: Double? = nil,
        studentScoreWeight: Double? = nil,
        penaltyPerDay: Double? = nil,
        maxDays: Int? = nil,
        gradingMode: GradingMode? = nil,
        minPeerReviewsRequired: Int? = nil,
        criteria: [CriterionDefinitionDto]? = nil
    ) async -> Bool {
        await savePost(
            postId: nil,
            type: type,
            title: title,
            text: text,
            deadline: deadline,
            maxScore: maxScore,
            taskType: taskType,
            solvableAfterDeadline: solvableAfterDeadline,
            minTeamSize: minTeamSize,
            maxTeamSize: maxTeamSize,
            captainMode: captainMode,
            votingDurationHours: votingDurationHours,
            predefinedTeamsCount: predefinedTeamsCount,
            allowJoinTeam: allowJoinTeam,
            allowLeaveTeam: allowLeaveTeam,
            allowStudentTransferCaptain: allowStudentTransferCaptain,
            failThreshold: failThreshold,
            successThreshold: successThreshold,
            studentScoreWeight: studentScoreWeight,
            penaltyPerDay: penaltyPerDay,
            maxDays: maxDays,
            gradingMode: gradingMode,
            minPeerReviewsRequired: minPeerReviewsRequired,
            criteria: criteria
        )
    }

    func savePost(
        postId: UUID?,
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
        allowStudentTransferCaptain: Bool? = nil,
        failThreshold: Double? = nil,
        successThreshold: Double? = nil,
        studentScoreWeight: Double? = nil,
        penaltyPerDay: Double? = nil,
        maxDays: Int? = nil,
        gradingMode: GradingMode? = nil,
        minPeerReviewsRequired: Int? = nil,
        criteria: [CriterionDefinitionDto]? = nil
    ) async -> Bool {
        guard PostValidator.isValidTitle(title) else {
            errorMessage = "Введите заголовок"
            return false
        }
        guard PostValidator.isValidText(text) else {
            errorMessage = "Введите текст"
            return false
        }
        if type == .task || type == .teamTask {
            guard PostValidator.isValidMaxScore(maxScore) else {
                errorMessage = "Максимальный балл должен быть больше 0"
                return false
            }
            if let d = deadline {
                guard postId != nil || PostValidator.isDeadlineValid(d) else {
                    errorMessage = "Дедлайн должен быть в будущем"
                    return false
                }
            }
        }
        if type == .task, gradingMode == .peerToPeer, (minPeerReviewsRequired ?? 0) < 1 {
            errorMessage = "Укажите минимум P2P-оцениваний"
            return false
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
                text: text.trimmingCharacters(in: .whitespacesAndNewlines),
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
                allowStudentTransferCaptain: type == .teamTask ? allowStudentTransferCaptain : nil,
                failThreshold: isTaskOrTeamTask ? failThreshold : nil,
                successThreshold: isTaskOrTeamTask ? successThreshold : nil,
                studentScoreWeight: isTaskOrTeamTask ? studentScoreWeight : nil,
                penaltyPerDay: isTaskOrTeamTask ? penaltyPerDay : nil,
                maxDays: isTaskOrTeamTask ? maxDays : nil,
                gradingMode: isTaskOrTeamTask ? gradingMode : nil,
                minPeerReviewsRequired: type == .task && gradingMode == .peerToPeer ? minPeerReviewsRequired : nil,
                criteria: isTaskOrTeamTask ? criteria : nil
            )
            if let postId {
                _ = try await service.updatePost(id: postId, request: request)
            } else {
                _ = try await service.createPost(courseId: courseId, request: request)
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
