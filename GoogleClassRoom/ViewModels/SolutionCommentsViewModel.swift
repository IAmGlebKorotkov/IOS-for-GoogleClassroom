import Foundation
import Combine

@MainActor
final class SolutionCommentsViewModel: ObservableObject {
    @Published var comments: [CommentDto] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?

    let solutionId: UUID
    private let service: CommentServiceProtocol

    init(solutionId: UUID, service: CommentServiceProtocol? = nil) {
        self.solutionId = solutionId
        self.service = service ?? ServiceLocator.shared.commentService
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await service.getSolutionComments(solutionId: solutionId, skip: 0, take: 50)
            comments = response.data?.records ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addComment(text: String) async {
        guard CommentValidator.isValidText(text) else {
            errorMessage = "Комментарий не может быть пустым"
            return
        }
        isSending = true
        errorMessage = nil
        defer { isSending = false }
        do {
            _ = try await service.addCommentToSolution(
                solutionId: solutionId,
                request: AddCommentRequest(text: text)
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteComment(_ id: UUID) async {
        do {
            _ = try await service.deleteComment(commentId: id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
