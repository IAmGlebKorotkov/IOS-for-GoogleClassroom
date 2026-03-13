

import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var isLoggedIn: Bool = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let auth: AuthServiceProtocol

    init(auth: AuthServiceProtocol? = nil) {
        self.auth = auth ?? ServiceLocator.shared.authService
        isLoggedIn = TokenStorage.shared.accessToken != nil
    }

    func login(email: String, password: String) async {
        guard AuthValidator.isValidEmail(email) else {
            errorMessage = "Неверный формат email"
            return
        }
        guard AuthValidator.isValidPassword(password) else {
            errorMessage = "Пароль должен быть от 6 до 20 символов"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await auth.login(email: email, password: password)
            isLoggedIn = true
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func register(email: String, password: String, credentials: String) async {
        guard AuthValidator.isValidEmail(email) else {
            errorMessage = "Неверный формат email"
            return
        }
        guard AuthValidator.isValidPassword(password) else {
            errorMessage = "Пароль должен быть от 6 до 20 символов"
            return
        }
        guard !credentials.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Введите имя"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await auth.register(email: email, password: password, credentials: credentials)
            await login(email: email, password: password)
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() async {
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await auth.logout()
        } catch {}
        TokenStorage.shared.clearAll()
        isLoggedIn = false
    }
}
