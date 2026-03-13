
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = ProfileViewModel()

    @State private var editName = ""
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var showPasswordSection = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Профиль") {
                    if let user = vm.user {
                        LabeledContent("Email", value: user.email)
                        HStack {
                            TextField("Имя", text: $editName)
                            Button("Сохранить") {
                                Task { await vm.updateCredentials(editName) }
                            }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.blue)
                            .disabled(editName == user.credentials || vm.isLoading)
                        }
                    } else if vm.isLoading {
                        ProgressView()
                    }
                }

                Section {
                    Button(showPasswordSection ? "Скрыть смену пароля" : "Изменить пароль") {
                        showPasswordSection.toggle()
                    }
                }

                if showPasswordSection {
                    Section("Смена пароля") {
                        SecureField("Текущий пароль", text: $oldPassword)
                        SecureField("Новый пароль", text: $newPassword)
                        Button("Применить") {
                            Task { await vm.changePassword(old: oldPassword, new: newPassword) }
                        }
                        .disabled(oldPassword.isEmpty || newPassword.isEmpty || vm.isLoading)
                    }
                }

                if let msg = vm.successMessage {
                    Section {
                        Text(msg).foregroundStyle(.green)
                    }
                }

                if let err = vm.errorMessage {
                    Section {
                        Text(err).foregroundStyle(.red)
                    }
                }

                Section {
                    Button("Выйти", role: .destructive) {
                        Task { await authVM.logout() }
                    }
                }
            }
            .navigationTitle("Профиль")
            .task {
                await vm.loadProfile()
                editName = vm.user?.credentials ?? ""
            }
            .onChange(of: vm.user) { _, user in
                if let user { editName = user.credentials }
            }
        }
    }
}
