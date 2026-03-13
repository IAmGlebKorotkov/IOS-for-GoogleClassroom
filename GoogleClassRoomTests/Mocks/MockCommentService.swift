

import Foundation
@testable import GoogleClassRoom

final class MockCommentService: CommentServiceProtocol {

    
    var addCommentError: Error?
    var editCommentError: Error?
    var deleteCommentError: Error?
    var replyError: Error?

    
    var stubCommentId = UUID()
    var stubComments: [CommentDto] = []
    var stubReplies: [CommentDto] = []

    
    var addPostCommentCallCount = 0
    var addSolutionCommentCallCount = 0
    var getPostCommentsCallCount = 0
    var getSolutionCommentsCallCount = 0
    var getRepliesCallCount = 0
    var replyCallCount = 0
    var editCallCount = 0
    var deleteCallCount = 0

    var lastAddedPostComment: AddCommentRequest?
    var lastAddedSolutionComment: AddCommentRequest?
    var lastEditedComment: EditCommentRequest?
    var lastDeletedCommentId: UUID?
    var lastRepliedToCommentId: UUID?

    func addCommentToPost(postId: UUID, request: AddCommentRequest) async throws -> ApiResponse<IdDto> {
        addPostCommentCallCount += 1
        lastAddedPostComment = request
        if let error = addCommentError { throw error }
        return ApiResponse(type: .success, message: nil, data: IdDto(id: stubCommentId))
    }

    func getPostComments(postId: UUID, skip: Int, take: Int) async throws -> ApiResponse<CommentListDto> {
        getPostCommentsCallCount += 1
        let list = CommentListDto(records: stubComments, totalRecords: stubComments.count)
        return ApiResponse(type: .success, message: nil, data: list)
    }

    func addCommentToSolution(solutionId: UUID, request: AddCommentRequest) async throws -> ApiResponse<IdDto> {
        addSolutionCommentCallCount += 1
        lastAddedSolutionComment = request
        if let error = addCommentError { throw error }
        return ApiResponse(type: .success, message: nil, data: IdDto(id: stubCommentId))
    }

    func getSolutionComments(solutionId: UUID, skip: Int, take: Int) async throws -> ApiResponse<CommentListDto> {
        getSolutionCommentsCallCount += 1
        let list = CommentListDto(records: stubComments, totalRecords: stubComments.count)
        return ApiResponse(type: .success, message: nil, data: list)
    }

    func getReplies(commentId: UUID, skip: Int, take: Int) async throws -> ApiResponse<CommentListDto> {
        getRepliesCallCount += 1
        let list = CommentListDto(records: stubReplies, totalRecords: stubReplies.count)
        return ApiResponse(type: .success, message: nil, data: list)
    }

    func replyToComment(commentId: UUID, request: AddCommentRequest) async throws -> ApiResponse<IdDto> {
        replyCallCount += 1
        lastRepliedToCommentId = commentId
        if let error = replyError { throw error }
        return ApiResponse(type: .success, message: nil, data: IdDto(id: stubCommentId))
    }

    func editComment(commentId: UUID, request: EditCommentRequest) async throws -> ApiResponse<IdDto> {
        editCallCount += 1
        lastEditedComment = request
        if let error = editCommentError { throw error }
        return ApiResponse(type: .success, message: nil, data: IdDto(id: commentId))
    }

    func deleteComment(commentId: UUID) async throws -> ApiResponse<IdDto> {
        deleteCallCount += 1
        lastDeletedCommentId = commentId
        if let error = deleteCommentError { throw error }
        return ApiResponse(type: .success, message: nil, data: IdDto(id: commentId))
    }
}
