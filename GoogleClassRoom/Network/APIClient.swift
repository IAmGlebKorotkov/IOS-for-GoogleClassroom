
import Foundation

final class APIClient {
    static let shared = APIClient()
    private init() {}
    
    static let baseURL = "http://37.21.130.4:5000"

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    func request<T: Decodable>(
        path: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        let url = try buildURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth, let token = TokenStorage.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await session.data(for: request)

        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let rawBody = String(data: data, encoding: .utf8) ?? "<non-utf8 data, \(data.count) bytes>"
        print("◀ [\(method.rawValue)] \(url.absoluteString) → \(statusCode)")
        print("◀ Body: \(rawBody)")

        do {
            try handleHTTPError(response: response, data: data)
        } catch {
            print("◀ HTTP Error thrown: \(error)")
            throw error
        }

        do {
            return try decode(T.self, from: data)
        } catch let apiErr as APIError {
            if case .decodingError(let inner) = apiErr {
                print("◀ Decoding error for \(T.self): \(inner)")
                print("◀ Raw JSON was: \(rawBody)")
            }
            throw apiErr
        }
    }
    

    func uploadFile(data fileData: Data, filename: String, mimeType: String) async throws -> ApiResponse<IdDto> {
        let url = try buildURL(path: "/api/files/upload", queryItems: nil)
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue

        if let token = TokenStorage.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        try handleHTTPError(response: response, data: data)
        return try decode(ApiResponse<IdDto>.self, from: data)
    }

    private func buildURL(path: String, queryItems: [URLQueryItem]?) throws -> URL {
        var components = URLComponents(string: APIClient.baseURL + path)!
        if let items = queryItems, !items.isEmpty {
            components.queryItems = items
        }
        guard let url = components.url else {
            throw APIError.unknown
        }
        return url
    }

    private func handleHTTPError(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw APIError.unknown }
        switch http.statusCode {
        case 200...299: return
        case 401: throw APIError.unauthorized
        case 403:
            if let msg = serverMessage(from: data), !msg.isEmpty {
                throw APIError.serverError(msg)
            }
            throw APIError.forbidden
        case 404: throw APIError.notFound
        default:
            if let msg = serverMessage(from: data), !msg.isEmpty {
                throw APIError.serverError(msg)
            }
            throw APIError.serverError("HTTP \(http.statusCode)")
        }
    }

    private func serverMessage(from data: Data) -> String? {
        if let apiResp = try? decoder.decode(ApiResponse<String?>.self, from: data),
           let msg = apiResp.message {
            return msg
        }
        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            return text
        }
        return nil
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw APIError.decodingError(error)
            print(APIError.decodingError(error))
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ value: Encodable) { self._encode = value.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}
