import Foundation

protocol FileServiceProtocol {
    func uploadFile(data: Data, filename: String, mimeType: String) async throws -> ApiResponse<IdDto>
    func getFileURL(id: UUID) -> URL
}
