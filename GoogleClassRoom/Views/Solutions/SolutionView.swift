import SwiftUI
import UniformTypeIdentifiers

struct SolutionView: View {

    @StateObject private var vm: SolutionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var solutionText = ""
    @State private var showFilePicker = false

    init(taskId: UUID, maxScore: Int?) {
        _vm = StateObject(wrappedValue: SolutionViewModel(taskId: taskId, maxScore: maxScore))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    if vm.isLoading && vm.solution == nil {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let solution = vm.solution {
                        currentSolutionSection(solution: solution)

                        if let solutionId = solution.id {
                            Divider().padding(.horizontal)
                            SolutionCommentsView(solutionId: solutionId)
                        }
                    } else {
                        noSolutionSection
                    }

                    if let error = vm.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    if let success = vm.successMessage {
                        Text(success)
                            .foregroundStyle(.green)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Моё решение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
        .task { await vm.load() }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                Task {
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        if let data = try? Data(contentsOf: url) {
                            await vm.uploadFile(
                                data: data,
                                filename: url.lastPathComponent,
                                mimeType: mimeType(for: url)
                            )
                        }
                    }
                }
            }
        }
    }

    private var noSolutionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Вы ещё не сдали решение")
                .font(.headline)
                .padding(.horizontal)

            TextEditor(text: $solutionText)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

            attachedFilesSection

            Button {
                showFilePicker = true
            } label: {
                Label(
                    vm.isUploading ? "Загрузка…" : "Прикрепить файл",
                    systemImage: "paperclip"
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundStyle(.primary)
                .cornerRadius(12)
            }
            .disabled(vm.isUploading)
            .padding(.horizontal)

            Button {
                Task { await vm.submit(text: solutionText) }
            } label: {
                Group {
                    if vm.isLoading {
                        ProgressView()
                    } else {
                        Text("Отправить решение")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .cornerRadius(12)
            }
            .disabled(vm.isLoading || vm.isUploading)
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var attachedFilesSection: some View {
        if !vm.uploadedFiles.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Прикреплённые файлы:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                ForEach(vm.uploadedFiles) { file in
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(.blue)
                        Text(file.name)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        Button {
                            vm.removeUploadedFile(id: file.id)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    @ViewBuilder
    private func currentSolutionSection(solution: StudentSolutionDetailsDto) -> some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Label(statusText(solution.status), systemImage: statusIcon(solution.status))
                    .font(.subheadline.bold())
                    .foregroundStyle(statusColor(solution.status))
                    .padding(8)
                    .background(statusColor(solution.status).opacity(0.1))
                    .cornerRadius(8)
                Spacer()
                if let score = solution.score {
                    Text("\(score)\(vm.maxScore.map { "/\($0)" } ?? "") баллов")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            if let text = solution.text, !text.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ваш ответ:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(text)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }

            if let files = solution.files, !files.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Прикреплённые файлы:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    ForEach(files, id: \.id) { file in
                        SolutionFileRowView(file: file)
                    }
                }
            }

            if vm.canSubmit && solution.status == .returned {
                Divider().padding(.horizontal)

                Text("Доработайте решение и отправьте снова:")
                    .font(.subheadline)
                    .padding(.horizontal)

                TextEditor(text: $solutionText)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .onAppear { solutionText = solution.text ?? "" }

                attachedFilesSection

                Button {
                    showFilePicker = true
                } label: {
                    Label(
                        vm.isUploading ? "Загрузка…" : "Прикрепить файл",
                        systemImage: "paperclip"
                    )
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .cornerRadius(12)
                }
                .disabled(vm.isUploading)
                .padding(.horizontal)

                Button {
                    Task { await vm.submit(text: solutionText) }
                } label: {
                    Text("Отправить повторно")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .disabled(vm.isLoading || vm.isUploading)
                .padding(.horizontal)
            }

            if vm.canCancel {
                Button(role: .destructive) {
                    Task { await vm.cancelSolution() }
                } label: {
                    Label("Отозвать решение", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundStyle(.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
        }
    }

    private func statusText(_ status: SolutionStatus) -> String {
        switch status {
        case .pending: return "На проверке"
        case .checked: return "Проверено"
        case .returned: return "Возвращено на доработку"
        }
    }

    private func statusIcon(_ status: SolutionStatus) -> String {
        switch status {
        case .pending: return "clock.fill"
        case .checked: return "checkmark.circle.fill"
        case .returned: return "arrow.uturn.left.circle.fill"
        }
    }

    private func statusColor(_ status: SolutionStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .checked: return .green
        case .returned: return .red
        }
    }

    private func mimeType(for url: URL) -> String {
        if let type = UTType(filenameExtension: url.pathExtension) {
            return type.preferredMIMEType ?? "application/octet-stream"
        }
        return "application/octet-stream"
    }
}

private struct SolutionFileRowView: View {
    let file: FileDto

    var body: some View {
        if let idString = file.id,
           let uuid = UUID(uuidString: idString),
           let url = URL(string: "\(APIClient.baseURL)/api/files/\(uuid.uuidString)") {
            Link(destination: url) {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(.blue)
                    Text(file.name ?? "Файл")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "arrow.down.circle")
                        .foregroundStyle(.blue)
                }
                .padding(.horizontal)
            }
        } else {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundStyle(.secondary)
                Text(file.name ?? "Файл")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
    }
}
