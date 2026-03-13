
import Foundation

final class FileService: FileServiceProtocol {
    func uploadFile(data: Data, filename: String, mimeType: String) async throws -> ApiResponse<IdDto> {
        return try await APIClient.shared.uploadFile(data: data, filename: filename, mimeType: mimeType)
    }

    func getFileURL(id: UUID) -> URL {
        URL(string: "\(APIClient.baseURL)/api/files/\(id.uuidString)")!
    }
}
