

import SwiftUI

struct CreateCourseView: View {

    @ObservedObject var vm: CourseListViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Название курса") {
                    TextField("Введите название", text: $title)
                }

                if let error = vm.errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Новый курс")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        Task {
                            await vm.createCourse(title: title)
                            if vm.errorMessage == nil { dismiss() }
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || vm.isLoading)
                }
            }
        }
    }
}
