

import Foundation
@testable import GoogleClassRoom

final class MockPostService: PostServiceProtocol {

    
    var createPostError: Error?
    var deletePostError: Error?
    var getFeedError: Error?

    
    var stubPostId = UUID()
    var stubFeedItems: [CourseFeedItemDto] = []
    var stubPost: PostDetailsDto? = nil

    
    var createCallCount = 0
    var deleteCallCount = 0
    var getFeedCallCount = 0
    var lastCreatedRequest: CreatePostRequest?
    var lastDeletedPostId: UUID?

    func createPost(courseId: UUID, request: CreatePostRequest) async throws -> ApiResponse<IdDto> {
        createCallCount += 1
        lastCreatedRequest = request
        if let error = createPostError { throw error }
        return ApiResponse(type: .success, message: nil, data: IdDto(id: stubPostId))
    }

    func getPost(id: UUID) async throws -> ApiResponse<PostDetailsDto> {
        let post = stubPost ?? PostDetailsDto(
            id: id,
            type: .post,
            title: "Test Post",
            text: "Test content",
            deadline: nil,
            maxScore: nil,
            taskType: nil,
            solvableAfterDeadline: nil,
            files: nil,
            userSolution: nil
        )
        return ApiResponse(type: .success, message: nil, data: post)
    }

    func updatePost(id: UUID, request: CreatePostRequest) async throws -> ApiResponse<IdDto> {
        return ApiResponse(type: .success, message: nil, data: IdDto(id: id))
    }

    func deletePost(id: UUID) async throws -> ApiResponse<IdDto> {
        deleteCallCount += 1
        lastDeletedPostId = id
        if let error = deletePostError { throw error }
        return ApiResponse(type: .success, message: nil, data: IdDto(id: id))
    }

    func getFeed(courseId: UUID, skip: Int, take: Int) async throws -> ApiResponse<FeedResponseDto> {
        getFeedCallCount += 1
        if let error = getFeedError { throw error }
        let feed = FeedResponseDto(records: stubFeedItems, totalRecords: stubFeedItems.count)
        return ApiResponse(type: .success, message: nil, data: feed)
    }
}
