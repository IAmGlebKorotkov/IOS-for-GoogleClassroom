import SwiftUI
import UniformTypeIdentifiers

struct TeamSolutionView: View {

    @StateObject private var vm: TeamSolutionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var solutionText = ""
    @State private var showFilePicker = false

    init(taskId: UUID, maxScore: Int?) {
        _vm = StateObject(wrappedValue: TeamSolutionViewModel(taskId: taskId, maxScore: maxScore))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    if vm.isLoading && vm.solution == nil {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let solution = vm.solution {
                        existingSolutionSection(solution: solution)
                        distributionButton(solution: solution)
                    } else {
                        submitSection
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
                .padding(.top)
            }
            .refreshable { await vm.load() }
            .navigationTitle("Командное решение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
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
            .task { await vm.load() }
        }
    }

    @ViewBuilder
    private func distributionButton(solution: StudentTeamSolutionDetailsDto) -> some View {
        let isAvailable = solution.status == .checked
        let title: String = {
            if !isAvailable { return "Распределение оценок (доступно после проверки)" }
            return vm.isCaptain ? "Распределить оценки" : "Распределение оценок"
        }()

        if isAvailable {
            NavigationLink {
                GradeDistributionView(
                    teamId: solution.team.id,
                    assignmentId: vm.taskId,
                    teamName: solution.team.name,
                    isCaptain: vm.isCaptain
                )
            } label: {
                Label(title, systemImage: "chart.pie")
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.orange.opacity(0.15))
                    .foregroundStyle(.orange).cornerRadius(12)
            }
            .padding(.horizontal)
        } else {
            Label(title, systemImage: "chart.pie")
                .frame(maxWidth: .infinity).padding()
                .background(Color(.systemGray5))
                .foregroundStyle(.secondary).cornerRadius(12)
                .padding(.horizontal)
        }
    }

    private var submitSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ответ команды")
                .font(.headline)
                .padding(.horizontal)

            TextField("Введите ответ команды…", text: $solutionText, axis: .vertical)
                .lineLimit(4...10)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

            filesSection

            Button {
                Task { await vm.submit(text: solutionText) }
            } label: {
                Group {
                    if vm.isLoading {
                        ProgressView()
                    } else {
                        Label("Отправить решение", systemImage: "paperplane.fill")
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

    private func existingSolutionSection(solution: StudentTeamSolutionDetailsDto) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            solutionStatusBadge(solution: solution)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 4) {
                Text("Команда: \(solution.team.name)")
                    .font(.subheadline.bold())
                    .padding(.horizontal)
                Text("Сдал: \(solution.submittedBy.credentials)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            if let text = solution.text, !text.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ответ:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    Text(text)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }

            if let files = solution.files, !files.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Прикреплённые файлы:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    ForEach(files, id: \.id) { file in
                        solutionFileRow(file: file)
                    }
                }
            }

            if vm.canSubmit {
                VStack(alignment: .leading, spacing: 12) {
                    Divider().padding(.horizontal)
                    Text("Исправить решение")
                        .font(.headline)
                        .padding(.horizontal)

                    TextField("Новый ответ…", text: $solutionText, axis: .vertical)
                        .lineLimit(4...10)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .onAppear { solutionText = solution.text ?? "" }

                    filesSection

                    Button {
                        Task { await vm.submit(text: solutionText) }
                    } label: {
                        Label("Пересдать", systemImage: "arrow.uturn.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                    .disabled(vm.isLoading)
                    .padding(.horizontal)
                }
            }

            if vm.canCancel {
                Button(role: .destructive) {
                    Task { await vm.cancelSolution() }
                } label: {
                    Label("Отозвать решение", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
        }
    }

    private var filesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !vm.uploadedFiles.isEmpty {
                ForEach(vm.uploadedFiles) { file in
                    HStack {
                        Image(systemName: "doc.fill").foregroundStyle(.blue)
                        Text(file.name).font(.subheadline).lineLimit(1)
                        Spacer()
                        Button { vm.removeUploadedFile(id: file.id) } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            Button {
                showFilePicker = true
            } label: {
                HStack {
                    if vm.isUploading {
                        ProgressView().scaleEffect(0.8)
                        Text("Загрузка…")
                    } else {
                        Image(systemName: "paperclip")
                        Text("Прикрепить файл")
                    }
                }
            }
            .disabled(vm.isUploading)
            .padding(.horizontal)
        }
    }

    private func solutionStatusBadge(solution: StudentTeamSolutionDetailsDto) -> some View {
        HStack {
            Image(systemName: statusIcon(solution.status)).foregroundStyle(statusColor(solution.status))
            Text(statusText(solution.status)).font(.subheadline.bold()).foregroundStyle(statusColor(solution.status))
            Spacer()
            if let score = solution.score, score > 0 {
                Text("\(score) баллов").font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(statusColor(solution.status).opacity(0.1))
        .cornerRadius(8)
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

    private func statusText(_ status: SolutionStatus) -> String {
        switch status {
        case .pending: return "На проверке"
        case .checked: return "Проверено"
        case .returned: return "Возвращено"
        }
    }

    private func solutionFileRow(file: FileDto) -> some View {
        Group {
            if let idStr = file.id, let uuid = UUID(uuidString: idStr),
               let url = URL(string: "\(APIClient.baseURL)/api/files/\(uuid.uuidString)") {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "doc.fill").foregroundStyle(.blue)
                        Text(file.name ?? "Файл").font(.subheadline).lineLimit(1).foregroundStyle(.blue)
                        Spacer()
                        Image(systemName: "arrow.down.circle").foregroundStyle(.blue)
                    }
                    .padding(.horizontal)
                }
            } else {
                HStack {
                    Image(systemName: "doc.fill").foregroundStyle(.secondary)
                    Text(file.name ?? "Файл").font(.subheadline).foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
        }
    }

    private func mimeType(for url: URL) -> String {
        if let type = UTType(filenameExtension: url.pathExtension) {
            return type.preferredMIMEType ?? "application/octet-stream"
        }
        return "application/octet-stream"
    }
}
