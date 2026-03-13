

import Foundation
import Combine

@MainActor
final class PostDetailViewModel: ObservableObject {

    @Published var post: PostDetailsDto?
    @Published var comments: [CommentDto] = []
    @Published var isLoading = false
    @Published var isSendingComment = false
    @Published var errorMessage: String?

    let postId: UUID
    let courseId: UUID

    private let postService: PostServiceProtocol
    private let commentService: CommentServiceProtocol

    init(
        postId: UUID,
        courseId: UUID,
        postService: PostServiceProtocol? = nil,
        commentService: CommentServiceProtocol? = nil
    ) {
        self.postId = postId
        self.courseId = courseId
        self.postService = postService ?? ServiceLocator.shared.postService
        self.commentService = commentService ?? ServiceLocator.shared.commentService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let postResp = postService.getPost(id: postId)
            async let commentResp = commentService.getPostComments(postId: postId, skip: 0, take: 50)
            let (p, c) = try await (postResp, commentResp)
            post = p.data
            comments = c.data?.records ?? []
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addComment(text: String) async {
        guard CommentValidator.isValidText(text) else {
            errorMessage = "Комментарий не может быть пустым или длиннее 2000 символов"
            return
        }
        isSendingComment = true
        errorMessage = nil
        defer { isSendingComment = false }
        do {
            _ = try await commentService.addCommentToPost(
                postId: postId,
                request: AddCommentRequest(text: text)
            )
            let response = try await commentService.getPostComments(postId: postId, skip: 0, take: 50)
            comments = response.data?.records ?? []
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteComment(_ commentId: UUID) async {
        do {
            _ = try await commentService.deleteComment(commentId: commentId)
            comments.removeAll { $0.id == commentId }
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
