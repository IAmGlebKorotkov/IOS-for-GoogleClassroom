

import SwiftUI

struct RegisterView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var credentials = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Регистрация")
                .font(.largeTitle.bold())

            VStack(spacing: 12) {
                TextField("Имя и фамилия", text: $credentials)
                    .textContentType(.name)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                SecureField("Пароль (6–20 символов)", text: $password)
                    .textContentType(.newPassword)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }

            if let error = authVM.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    await authVM.register(email: email, password: password, credentials: credentials)
                }
            } label: {
                Group {
                    if authVM.isLoading {
                        ProgressView()
                    } else {
                        Text("Зарегистрироваться")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .disabled(authVM.isLoading)

            Spacer()
        }
        .padding(.horizontal, 24)
        .onChange(of: authVM.isLoggedIn) { _, loggedIn in
            if loggedIn { dismiss() }
        }
    }
}
