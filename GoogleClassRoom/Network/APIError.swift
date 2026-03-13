import Foundation

enum APIError: Error, LocalizedError {
    case unauthorized
    case forbidden
    case notFound
    case serverError(String)
    case invalidCredentials
    case decodingError(Error)
    case networkError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Необходима авторизация"
        case .forbidden: return "Доступ запрещён"
        case .notFound: return "Ресурс не найден"
        case .serverError(let msg): return msg
        case .invalidCredentials: return "Неверный email или пароль"
        case .decodingError(let e): return "Ошибка декодирования: \(e.localizedDescription)"
        case .networkError(let e): return "Ошибка сети: \(e.localizedDescription)"
        case .unknown: return "Неизвестная ошибка"
        }
    }
}
