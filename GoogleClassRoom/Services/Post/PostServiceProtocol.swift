

import Foundation

protocol PostServiceProtocol {
    func createPost(courseId: UUID, request: CreatePostRequest) async throws -> ApiResponse<IdDto>
    func getPost(id: UUID) async throws -> ApiResponse<PostDetailsDto>
    func updatePost(id: UUID, request: CreatePostRequest) async throws -> ApiResponse<IdDto>
    func deletePost(id: UUID) async throws -> ApiResponse<IdDto>
    func getFeed(courseId: UUID, skip: Int, take: Int) async throws -> ApiResponse<FeedResponseDto>
}
