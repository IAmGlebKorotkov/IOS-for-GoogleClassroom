import Foundation

struct UserRegisterRequest: Codable {
    let email: String
    let password: String
    let credentials: String?
}

struct UserLoginRequest: Codable {
    let email: String
    let password: String
}

struct UserChangePasswordRequest: Codable {
    let oldPassword: String?
    let newPassword: String?
}

enum ApiResponseType: Codable {
    case success
    case error

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = (intValue == 0) ? .success : .error
            return
        }
        let stringValue = try container.decode(String.self)
        switch stringValue.lowercased() {
        case "success", "0": self = .success
        default: self = .error
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .success: try container.encode("success")
        case .error: try container.encode("error")
        }
    }
}

struct ApiResponse<T: Codable>: Codable {
    let type: ApiResponseType
    let message: String?
    let data: T?
}

struct IdDto: Codable {
    let id: UUID
}

struct AuthValidator {
    static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6 && password.count <= 20
    }
}

struct AuthResponseDto: Codable {
    let accessToken: String
    let refreshToken: String
}
