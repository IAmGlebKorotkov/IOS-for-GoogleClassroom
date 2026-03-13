import Foundation

protocol CommentServiceProtocol {
    func addCommentToPost(postId: UUID, request: AddCommentRequest) async throws -> ApiResponse<IdDto>
    func getPostComments(postId: UUID, skip: Int, take: Int) async throws -> ApiResponse<CommentListDto>
    func addCommentToSolution(solutionId: UUID, request: AddCommentRequest) async throws -> ApiResponse<IdDto>
    func getSolutionComments(solutionId: UUID, skip: Int, take: Int) async throws -> ApiResponse<CommentListDto>
    func getReplies(commentId: UUID, skip: Int, take: Int) async throws -> ApiResponse<CommentListDto>
    func replyToComment(commentId: UUID, request: AddCommentRequest) async throws -> ApiResponse<IdDto>
    func editComment(commentId: UUID, request: EditCommentRequest) async throws -> ApiResponse<IdDto>
    func deleteComment(commentId: UUID) async throws -> ApiResponse<IdDto>
}
