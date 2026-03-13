

import SwiftUI

struct JoinCourseView: View {

    @ObservedObject var vm: CourseListViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Код приглашения") {
                    TextField("Введите код", text: $code)
                        .autocapitalization(.allCharacters)
                        .autocorrectionDisabled()
                }

                if let error = vm.errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Вступить в курс")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Вступить") {
                        Task {
                            await vm.joinCourse(code: code)
                            if vm.errorMessage == nil { dismiss() }
                        }
                    }
                    .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty || vm.isLoading)
                }
            }
        }
    }
}
