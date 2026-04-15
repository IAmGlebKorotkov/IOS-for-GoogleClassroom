import SwiftUI
import UniformTypeIdentifiers

struct CreatePostView: View {
    @StateObject private var vm: CreatePostViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var type: PostType = .post
    @State private var title = ""
    @State private var text = ""
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(86400)
    @State private var maxScore = 5
    @State private var taskType: TaskType = .mandatory
    @State private var solvableAfterDeadline = false
    @State private var showFilePicker = false
    // Team task
    @State private var minTeamSize = 2
    @State private var maxTeamSize = 4
    @State private var captainMode: CaptainSelectionMode = .firstMember
    @State private var votingDurationHours = 24
    @State private var predefinedTeamsCount = 0
    @State private var allowJoinTeam = true
    @State private var allowLeaveTeam = true
    @State private var allowStudentTransferCaptain = false

    init(courseId: UUID) {
        _vm = StateObject(wrappedValue: CreatePostViewModel(courseId: courseId))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Тип публикации") {
                    Picker("Тип", selection: $type) {
                        Text("Материал").tag(PostType.post)
                        Text("Задание").tag(PostType.task)
                        Text("Командное").tag(PostType.teamTask)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Содержание") {
                    TextField("Заголовок", text: $title)
                    TextField("Текст (необязательно)", text: $text, axis: .vertical)
                        .lineLimit(3...8)
                }

                if type == .task || type == .teamTask {
                    Section("Параметры задания") {
                        Picker("Тип задания", selection: $taskType) {
                            Text("Обязательное").tag(TaskType.mandatory)
                            Text("Дополнительное").tag(TaskType.optional)
                        }

                        Stepper("Максимальный балл: \(maxScore)", value: $maxScore, in: 1...100)

                        Toggle("Установить дедлайн", isOn: $hasDeadline)
                        if hasDeadline {
                            DatePicker(
                                "Дедлайн",
                                selection: $deadline,
                                in: Date()...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                        }

                        Toggle("Можно сдавать после дедлайна", isOn: $solvableAfterDeadline)
                    }
                }

                if type == .teamTask {
                    Section("Параметры команд") {
                        Stepper("Мин. размер команды: \(minTeamSize)", value: $minTeamSize, in: 1...20)
                        Stepper("Макс. размер команды: \(maxTeamSize)", value: $maxTeamSize, in: 1...50)
                        Stepper("Предопределённых команд: \(predefinedTeamsCount)", value: $predefinedTeamsCount, in: 0...30)
                    }

                    Section("Капитан") {
                        Picker("Выбор капитана", selection: $captainMode) {
                            Text("Первый участник").tag(CaptainSelectionMode.firstMember)
                            Text("Голосование").tag(CaptainSelectionMode.votingAndLottery)
                            Text("Назначает учитель").tag(CaptainSelectionMode.teacherFixed)
                        }
                        if captainMode == .votingAndLottery {
                            Stepper("Голосование: \(votingDurationHours) ч.", value: $votingDurationHours, in: 1...168)
                        }
                        Toggle("Студент может передать капитанство", isOn: $allowStudentTransferCaptain)
                    }

                    Section("Управление командой") {
                        Toggle("Студент может вступить в команду", isOn: $allowJoinTeam)
                        Toggle("Студент может покинуть команду", isOn: $allowLeaveTeam)
                    }
                }

                Section("Прикреплённые файлы") {
                    if vm.uploadedFiles.isEmpty {
                        Text("Нет прикреплённых файлов")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
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
                }

                if let err = vm.errorMessage {
                    Section {
                        Text(err).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Новая публикация")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        Task {
                            let success = await vm.createPost(
                                type: type,
                                title: title,
                                text: text,
                                deadline: hasDeadline ? deadline : nil,
                                maxScore: maxScore,
                                taskType: taskType,
                                solvableAfterDeadline: solvableAfterDeadline,
                                minTeamSize: type == .teamTask ? minTeamSize : nil,
                                maxTeamSize: type == .teamTask ? maxTeamSize : nil,
                                captainMode: type == .teamTask ? captainMode : nil,
                                votingDurationHours: type == .teamTask && captainMode == .votingAndLottery ? votingDurationHours : nil,
                                predefinedTeamsCount: type == .teamTask && predefinedTeamsCount > 0 ? predefinedTeamsCount : nil,
                                allowJoinTeam: type == .teamTask ? allowJoinTeam : nil,
                                allowLeaveTeam: type == .teamTask ? allowLeaveTeam : nil,
                                allowStudentTransferCaptain: type == .teamTask ? allowStudentTransferCaptain : nil
                            )
                            if success { dismiss() }
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || vm.isLoading || vm.isUploading)
                }
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
    }

    private func mimeType(for url: URL) -> String {
        if let type = UTType(filenameExtension: url.pathExtension) {
            return type.preferredMIMEType ?? "application/octet-stream"
        }
        return "application/octet-stream"
    }
}
