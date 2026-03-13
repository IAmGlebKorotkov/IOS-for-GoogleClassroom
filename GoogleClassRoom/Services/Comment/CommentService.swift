import Foundation

private struct IdRequestDto: Codable {
    let id: UUID
}

private typealias CommentListResponse = ApiResponse<[CommentDto]>

final class CommentService: CommentServiceProtocol {
    private let client = APIClient.shared

    func addCommentToPost(postId: UUID, request: AddCommentRequest) async throws -> ApiResponse<IdDto> {
        let response: ApiResponse<IdRequestDto> = try await client.request(
            path: "/api/post/\(postId.uuidString)/comment",
            method: .post,
            body: request
        )
        return ApiResponse(type: response.type, message: response.message, data: response.data.map { IdDto(id: $0.id) })
    }

    func getPostComments(postId: UUID, skip: Int, take: Int) async throws -> ApiResponse<CommentListDto> {
        let response: CommentListResponse = try await client.request(
            path: "/api/post/\(postId.uuidString)/comment"
        )
        let listDto = response.data.map { CommentListDto(records: $0, totalRecords: $0.count) }
        return ApiResponse(type: response.type, message: response.message, data: listDto)
    }

    func addCommentToSolution(solutionId: UUID, request: AddCommentRequest) async throws -> ApiResponse<IdDto> {
        let response: ApiResponse<IdRequestDto> = try await client.request(
            path: "/api/solution/\(solutionId.uuidString)/comment",
            method: .post,
            body: request
        )
        return ApiResponse(type: response.type, message: response.message, data: response.data.map { IdDto(id: $0.id) })
    }

    func getSolutionComments(solutionId: UUID, skip: Int, take: Int) async throws -> ApiResponse<CommentListDto> {
        let response: CommentListResponse = try await client.request(
            path: "/api/solution/\(solutionId.uuidString)/comment"
        )
        let listDto = response.data.map { CommentListDto(records: $0, totalRecords: $0.count) }
        return ApiResponse(type: response.type, message: response.message, data: listDto)
    }

    func getReplies(commentId: UUID, skip: Int, take: Int) async throws -> ApiResponse<CommentListDto> {
        let response: CommentListResponse = try await client.request(
            path: "/api/comment/\(commentId.uuidString)/replies"
        )
        let listDto = response.data.map { CommentListDto(records: $0, totalRecords: $0.count) }
        return ApiResponse(type: response.type, message: response.message, data: listDto)
    }

    func replyToComment(commentId: UUID, request: AddCommentRequest) async throws -> ApiResponse<IdDto> {
        let response: ApiResponse<IdRequestDto> = try await client.request(
            path: "/api/comment/\(commentId.uuidString)/reply",
            method: .post,
            body: request
        )
        return ApiResponse(type: response.type, message: response.message, data: response.data.map { IdDto(id: $0.id) })
    }

    func editComment(commentId: UUID, request: EditCommentRequest) async throws -> ApiResponse<IdDto> {
        let response: ApiResponse<IdRequestDto> = try await client.request(
            path: "/api/comment/\(commentId.uuidString)",
            method: .put,
            body: request
        )
        return ApiResponse(type: response.type, message: response.message, data: response.data.map { IdDto(id: $0.id) })
    }

    func deleteComment(commentId: UUID) async throws -> ApiResponse<IdDto> {
        let response: ApiResponse<IdRequestDto> = try await client.request(
            path: "/api/comment/\(commentId.uuidString)",
            method: .delete
        )
        return ApiResponse(type: response.type, message: response.message, data: response.data.map { IdDto(id: $0.id) })
    }
}
