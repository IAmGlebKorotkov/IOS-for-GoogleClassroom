
import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: UserDto?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let userService: UserServiceProtocol
    private let authService: AuthServiceProtocol

    init(userService: UserServiceProtocol? = nil, authService: AuthServiceProtocol? = nil) {
        self.userService = userService ?? ServiceLocator.shared.userService
        self.authService = authService ?? ServiceLocator.shared.authService
    }

    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await userService.getCurrentUser()
            user = response.data
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateCredentials(_ credentials: String) async {
        guard !credentials.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Имя не может быть пустым"
            return
        }
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }
        do {
            _ = try await userService.updateUser(credentials: credentials, email: nil)
            successMessage = "Имя обновлено"
            await loadProfile()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func changePassword(old: String, new: String) async {
        guard !old.isEmpty, !new.isEmpty else {
            errorMessage = "Заполните все поля"
            return
        }
        guard AuthValidator.isValidPassword(new) else {
            errorMessage = "Новый пароль: от 6 до 20 символов"
            return
        }
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }
        do {
            _ = try await authService.changePassword(oldPassword: old, newPassword: new)
            successMessage = "Пароль изменён"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
