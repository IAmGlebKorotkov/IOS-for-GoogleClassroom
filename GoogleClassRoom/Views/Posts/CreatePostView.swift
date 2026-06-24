import SwiftUI
import UniformTypeIdentifiers

struct CreatePostView: View {
    @StateObject private var vm: CreatePostViewModel
    @Environment(\.dismiss) private var dismiss

    private let editingPostId: UUID?
    private let onSaved: (() -> Void)?

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
    // Grading criteria
    @State private var weightedCriteria: [WeightedCriterionDraft] = [
        WeightedCriterionDraft(title: "Критерий", maxScore: 10, weight: 1)
    ]
    @State private var bonusCriteria: [ScoredCriterionDraft] = []
    @State private var penaltyCriteria: [ScoredCriterionDraft] = []
    @State private var qualityCriteria: [QualityCriterionDraft] = []
    @State private var blockingCriteria: [BlockingCriterionDraft] = []
    @State private var useFailThreshold = false
    @State private var failThreshold = 50.0
    @State private var useSuccessThreshold = false
    @State private var successThreshold = 90.0
    @State private var useStudentScoreWeight = false
    @State private var studentScoreWeight = 0.2
    @State private var useLatePenalty = false
    @State private var penaltyPerDay = 1.0
    @State private var maxDays = 5
    @State private var gradingMode: GradingMode = .teacherReview
    @State private var minPeerReviewsRequired = 1

    init(courseId: UUID) {
        editingPostId = nil
        onSaved = nil
        _vm = StateObject(wrappedValue: CreatePostViewModel(courseId: courseId))
    }

    init(courseId: UUID, editingPost post: PostDetailsDto, onSaved: (() -> Void)? = nil) {
        editingPostId = post.id
        self.onSaved = onSaved
        _vm = StateObject(
            wrappedValue: CreatePostViewModel(
                courseId: courseId,
                uploadedFiles: Self.uploadedFiles(from: post.files)
            )
        )
        _type = State(initialValue: post.type)
        _title = State(initialValue: post.title)
        _text = State(initialValue: post.text)
        _hasDeadline = State(initialValue: post.deadline != nil)
        _deadline = State(initialValue: post.deadline ?? Date().addingTimeInterval(86400))
        _maxScore = State(initialValue: max(post.maxScore ?? 5, 1))
        _taskType = State(initialValue: post.taskType ?? .mandatory)
        _solvableAfterDeadline = State(initialValue: post.solvableAfterDeadline ?? false)
        _minTeamSize = State(initialValue: max(post.minTeamSize ?? 2, 1))
        _maxTeamSize = State(initialValue: max(post.maxTeamSize ?? 4, 1))
        _captainMode = State(initialValue: post.captainMode ?? .firstMember)
        _votingDurationHours = State(initialValue: max(post.votingDurationHours ?? 24, 1))
        _predefinedTeamsCount = State(initialValue: max(post.predefinedTeamsCount ?? 0, 0))
        _allowJoinTeam = State(initialValue: post.allowJoinTeam ?? true)
        _allowLeaveTeam = State(initialValue: post.allowLeaveTeam ?? true)
        _allowStudentTransferCaptain = State(initialValue: post.allowStudentTransferCaptain ?? false)
        _weightedCriteria = State(initialValue: Self.weightedDrafts(from: post.criteria))
        _bonusCriteria = State(initialValue: Self.scoredDrafts(from: post.criteria, direction: .add))
        _penaltyCriteria = State(initialValue: Self.scoredDrafts(from: post.criteria, direction: .subtract))
        _qualityCriteria = State(initialValue: Self.qualityDrafts(from: post.criteria))
        _blockingCriteria = State(initialValue: Self.blockingDrafts(from: post.criteria))
        _useFailThreshold = State(initialValue: post.failThreshold != nil)
        _failThreshold = State(initialValue: Self.percentDraftValue(post.failThreshold, fallback: 50))
        _useSuccessThreshold = State(initialValue: post.successThreshold != nil)
        _successThreshold = State(initialValue: Self.percentDraftValue(post.successThreshold, fallback: 90))
        _useStudentScoreWeight = State(initialValue: post.studentScoreWeight != nil)
        _studentScoreWeight = State(initialValue: post.studentScoreWeight ?? 0.2)
        _useLatePenalty = State(initialValue: post.penaltyPerDay != nil)
        _penaltyPerDay = State(initialValue: post.penaltyPerDay ?? 1)
        _maxDays = State(initialValue: max(post.maxDays ?? 5, 1))
        _gradingMode = State(initialValue: post.gradingMode ?? .teacherReview)
        _minPeerReviewsRequired = State(initialValue: max(post.minPeerReviewsRequired ?? 1, 1))
    }

    private static func uploadedFiles(from files: [FileDto]?) -> [UploadedFileItem] {
        (files ?? []).compactMap { file in
            guard let idString = file.id, let id = UUID(uuidString: idString) else { return nil }
            return UploadedFileItem(id: id, name: file.name ?? "Файл")
        }
    }

    private static func weightedDrafts(from criteria: [CriterionDto]?) -> [WeightedCriterionDraft] {
        sorted(criteria)
            .filter { $0.type == .weighted }
            .map {
                WeightedCriterionDraft(
                    id: $0.id,
                    sourceId: $0.id,
                    title: $0.title ?? "Критерий",
                    maxScore: $0.maxScore ?? 10,
                    weight: $0.weight ?? 1
                )
            }
    }

    private static func scoredDrafts(from criteria: [CriterionDto]?, direction: CriterionDirection) -> [ScoredCriterionDraft] {
        sorted(criteria)
            .filter { $0.type == .bonusPenalty && $0.direction == direction }
            .map {
                ScoredCriterionDraft(
                    id: $0.id,
                    sourceId: $0.id,
                    title: $0.title ?? (direction == .add ? "Бонус" : "Штраф"),
                    score: $0.score ?? 1
                )
            }
    }

    private static func qualityDrafts(from criteria: [CriterionDto]?) -> [QualityCriterionDraft] {
        sorted(criteria)
            .filter { $0.type == .quality }
            .map {
                QualityCriterionDraft(
                    id: $0.id,
                    sourceId: $0.id,
                    title: $0.title ?? "Качество",
                    threshold: percentDraftValue($0.threshold, fallback: 80),
                    score: $0.score ?? 1,
                    direction: $0.direction ?? .add
                )
            }
    }

    private static func blockingDrafts(from criteria: [CriterionDto]?) -> [BlockingCriterionDraft] {
        sorted(criteria)
            .filter { $0.type == .blocking }
            .map {
                BlockingCriterionDraft(
                    id: $0.id,
                    sourceId: $0.id,
                    title: $0.title ?? "Блокировка",
                    maxAllowedScore: $0.maxAllowedScore ?? 3
                )
            }
    }

    private static func sorted(_ criteria: [CriterionDto]?) -> [CriterionDto] {
        (criteria ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }

    private static func percentDraftValue(_ value: Double?, fallback: Double) -> Double {
        guard let value else { return fallback }
        return value > 1 ? value : value * 100
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
                    .disabled(isEditing)
                }

                Section("Содержание") {
                    TextField("Заголовок", text: $title)
                    TextField("Текст", text: $text, axis: .vertical)
                        .lineLimit(3...8)
                }

                if type == .task || type == .teamTask {
                    Section("Параметры задания") {
                        Picker("Тип задания", selection: $taskType) {
                            Text("Обязательное").tag(TaskType.mandatory)
                            Text("Дополнительное").tag(TaskType.optional)
                        }

                        SpacedIntStepper(title: "Максимальный балл: \(maxScore)", value: $maxScore, range: 1...100)

                        Toggle("Установить дедлайн", isOn: $hasDeadline)
                        if hasDeadline {
                            DatePicker(
                                "Дедлайн",
                                selection: $deadline,
                                in: deadlineLowerBound...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                        }

                        Toggle("Можно сдавать после дедлайна", isOn: $solvableAfterDeadline)
                    }

                    gradingCriteriaSection
                    gradingModeSection
                    advancedGradingSection
                }

                if type == .teamTask {
                    Section("Параметры команд") {
                        SpacedIntStepper(title: "Мин. размер команды: \(minTeamSize)", value: $minTeamSize, range: 1...20)
                        SpacedIntStepper(title: "Макс. размер команды: \(maxTeamSize)", value: $maxTeamSize, range: 1...50)
                        SpacedIntStepper(title: "Предопределённых команд: \(predefinedTeamsCount)", value: $predefinedTeamsCount, range: 0...30)
                    }

                    Section("Капитан") {
                        Picker("Выбор капитана", selection: $captainMode) {
                            Text("Первый участник").tag(CaptainSelectionMode.firstMember)
                            Text("Голосование").tag(CaptainSelectionMode.votingAndLottery)
                            Text("Назначает учитель").tag(CaptainSelectionMode.teacherFixed)
                        }
                        if captainMode == .votingAndLottery {
                            SpacedIntStepper(title: "Голосование: \(votingDurationHours) ч.", value: $votingDurationHours, range: 1...168)
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
            .navigationTitle(isEditing ? "Редактирование" : "Новая публикация")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Сохранить" : "Создать") {
                        Task {
                            let success = await vm.savePost(
                                postId: editingPostId,
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
                                allowStudentTransferCaptain: type == .teamTask ? allowStudentTransferCaptain : nil,
                                failThreshold: useFailThreshold ? normalizedPercent(failThreshold) : nil,
                                successThreshold: useSuccessThreshold ? normalizedPercent(successThreshold) : nil,
                                studentScoreWeight: useStudentScoreWeight ? studentScoreWeight : nil,
                                penaltyPerDay: useLatePenalty ? penaltyPerDay : nil,
                                maxDays: useLatePenalty ? maxDays : nil,
                                gradingMode: gradingMode,
                                minPeerReviewsRequired: type == .task && gradingMode == .peerToPeer ? minPeerReviewsRequired : nil,
                                criteria: criteriaPayload.isEmpty ? nil : criteriaPayload
                            )
                            if success {
                                onSaved?()
                                dismiss()
                            }
                        }
                    }
                    .disabled(
                        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        vm.isLoading ||
                        vm.isUploading
                    )
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

    private var isEditing: Bool {
        editingPostId != nil
    }

    private var deadlineLowerBound: Date {
        let now = Date()
        return isEditing && deadline < now ? deadline : now
    }

    private func mimeType(for url: URL) -> String {
        if let type = UTType(filenameExtension: url.pathExtension) {
            return type.preferredMIMEType ?? "application/octet-stream"
        }
        return "application/octet-stream"
    }

    private var gradingCriteriaSection: some View {
        Section("Критерии оценивания") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Весовые модификаторы", systemImage: "slider.horizontal.3")
                        .font(.subheadline.bold())
                    Spacer()
                    Text("Σ весов \(formatScore(totalWeight))")
                        .font(.caption)
                        .foregroundStyle(abs(totalWeight - 1) < 0.001 ? .green : .orange)
                }

                ForEach($weightedCriteria) { $criterion in
                    VStack(alignment: .leading, spacing: 12) {
                        editableTitleField("Название критерия", text: $criterion.title)

                        SpacedDoubleStepper(title: "Макс. \(formatScore(criterion.maxScore))", value: $criterion.maxScore, range: 0.5...100, step: 0.5)
                        SpacedDoubleStepper(title: "Вес \(formatWeight(criterion.weight))", value: $criterion.weight, range: 0.05...5, step: 0.05)

                        HStack {
                            Spacer()
                            removeButton("Удалить критерий") {
                                weightedCriteria.removeAll { $0.id == criterion.id }
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Button {
                        weightedCriteria.append(WeightedCriterionDraft(title: "Новый критерий", maxScore: 10, weight: 1))
                    } label: {
                        Label("Добавить весовой критерий", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button("Нормализовать") {
                        normalizeWeights()
                    }
                    .disabled(weightedCriteria.isEmpty || totalWeight == 0)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Label("Бонусные модификаторы", systemImage: "plus.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)

                ForEach($bonusCriteria) { $criterion in
                    scoredCriterionRow(criterion: $criterion, collection: .bonus)
                }

                Button {
                    bonusCriteria.append(ScoredCriterionDraft(title: "Новый бонус", score: 1))
                } label: {
                    Label("Добавить бонус", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Label("Штрафные модификаторы", systemImage: "minus.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)

                ForEach($penaltyCriteria) { $criterion in
                    scoredCriterionRow(criterion: $criterion, collection: .penalty)
                }

                Button {
                    penaltyCriteria.append(ScoredCriterionDraft(title: "Новый штраф", score: 1))
                } label: {
                    Label("Добавить штраф", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            LabeledContent("Макс. по критериям", value: formatScore(maxCriteriaScore))
        }
    }

    private var advancedGradingSection: some View {
        Section("Расширенные модификаторы") {
            Toggle("Порог незачёта", isOn: $useFailThreshold)
            if useFailThreshold {
                SpacedDoubleStepper(title: "Ниже \(formatScore(failThreshold))%", value: $failThreshold, range: 0...100, step: 1)
            }

            Toggle("Порог максимальной оценки", isOn: $useSuccessThreshold)
            if useSuccessThreshold {
                SpacedDoubleStepper(title: "От \(formatScore(successThreshold))%", value: $successThreshold, range: 0...100, step: 1)
            }

            Toggle("Учитывать самооценку", isOn: $useStudentScoreWeight)
            if useStudentScoreWeight {
                SpacedDoubleStepper(title: "Вес \(formatWeight(studentScoreWeight))", value: $studentScoreWeight, range: 0.05...1, step: 0.05)
            }

            Toggle("Штраф за просрочку", isOn: $useLatePenalty)
            if useLatePenalty {
                SpacedDoubleStepper(title: "−\(formatScore(penaltyPerDay)) балл/день", value: $penaltyPerDay, range: 0...20, step: 0.5)
                SpacedIntStepper(title: "Макс. дней: \(maxDays)", value: $maxDays, range: 1...365)
            }

            DisclosureGroup("Коэффициенты качества") {
                ForEach($qualityCriteria) { $criterion in
                    VStack(alignment: .leading, spacing: 12) {
                        editableTitleField("Название модификатора", text: $criterion.title)
                        Picker("Направление", selection: $criterion.direction) {
                            Text("Выше порога → бонус").tag(CriterionDirection.add)
                            Text("Ниже порога → штраф").tag(CriterionDirection.subtract)
                        }
                        SpacedDoubleStepper(title: "Порог \(formatScore(criterion.threshold))%", value: $criterion.threshold, range: 0...100, step: 1)
                        SpacedDoubleStepper(title: "\(criterion.direction == .add ? "+" : "−")\(formatScore(criterion.score)) балл.", value: $criterion.score, range: 0...100, step: 0.5)
                        HStack {
                            Spacer()
                            removeButton("Удалить модификатор") {
                                qualityCriteria.removeAll { $0.id == criterion.id }
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }

                Button {
                    qualityCriteria.append(QualityCriterionDraft(title: "Качество", threshold: 80, score: 1, direction: .add))
                } label: {
                    Label("Добавить качество", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            DisclosureGroup("Блокирующие модификаторы") {
                ForEach($blockingCriteria) { $criterion in
                    VStack(alignment: .leading, spacing: 12) {
                        editableTitleField("Название модификатора", text: $criterion.title)
                        SpacedDoubleStepper(title: "Итог не выше \(formatScore(criterion.maxAllowedScore))", value: $criterion.maxAllowedScore, range: 0...100, step: 0.5)
                        HStack {
                            Spacer()
                            removeButton("Удалить модификатор") {
                                blockingCriteria.removeAll { $0.id == criterion.id }
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }

                Button {
                    blockingCriteria.append(BlockingCriterionDraft(title: "Блокировка", maxAllowedScore: 3))
                } label: {
                    Label("Добавить блокировку", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var gradingModeSection: some View {
        Section("Механизм оценивания") {
            Picker("Проверка", selection: $gradingMode) {
                Label("Преподаватель", systemImage: "person.text.rectangle")
                    .tag(GradingMode.teacherReview)
                Label("P2P", systemImage: "person.2.wave.2")
                    .tag(GradingMode.peerToPeer)
            }
            .pickerStyle(.segmented)

            if gradingMode == .peerToPeer {
                if type == .task {
                    SpacedIntStepper(
                        title: "Минимум оцениваний: \(minPeerReviewsRequired)",
                        value: $minPeerReviewsRequired,
                        range: 1...20
                    )
                } else {
                    Label("Студенту нужно оценить одну другую команду", systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func scoredCriterionRow(criterion: Binding<ScoredCriterionDraft>, collection: ScoredCriterionCollection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            editableTitleField(collection == .bonus ? "Название бонуса" : "Название штрафа", text: criterion.title)
            SpacedDoubleStepper(title: "Баллы: \(formatScore(criterion.wrappedValue.score))", value: criterion.score, range: 0...100, step: 0.5)

            HStack {
                Spacer()
                removeButton(collection == .bonus ? "Удалить бонус" : "Удалить штраф") {
                    switch collection {
                    case .bonus:
                        bonusCriteria.removeAll { $0.id == criterion.wrappedValue.id }
                    case .penalty:
                        penaltyCriteria.removeAll { $0.id == criterion.wrappedValue.id }
                    }
                }
            }
        }
        .padding(.vertical, 10)
    }

    private func editableTitleField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.sentences)
        }
    }

    private func removeButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(role: .destructive, action: action) {
            Label(title, systemImage: "trash")
                .font(.caption)
        }
        .buttonStyle(.borderless)
    }

    private var totalWeight: Double {
        weightedCriteria.reduce(0) { $0 + $1.weight }
    }

    private var maxCriteriaScore: Double {
        let weighted = weightedCriteria.reduce(0) { $0 + $1.maxScore * $1.weight }
        let bonus = bonusCriteria.reduce(0) { $0 + $1.score }
        return weighted + bonus
    }

    private var criteriaPayload: [CriterionDefinitionDto] {
        var index = 0
        var result: [CriterionDefinitionDto] = []

        for criterion in weightedCriteria where !criterion.trimmedTitle.isEmpty {
            result.append(
                CriterionDefinitionDto(
                    id: criterion.sourceId,
                    type: .weighted,
                    title: criterion.trimmedTitle,
                    orderIndex: index,
                    maxScore: criterion.maxScore,
                    weight: max(criterion.weight, minimumCriterionWeight)
                )
            )
            index += 1
        }

        for criterion in bonusCriteria where !criterion.trimmedTitle.isEmpty {
            result.append(
                CriterionDefinitionDto(
                    id: criterion.sourceId,
                    type: .bonusPenalty,
                    title: criterion.trimmedTitle,
                    orderIndex: index,
                    score: criterion.score,
                    direction: .add
                )
            )
            index += 1
        }

        for criterion in penaltyCriteria where !criterion.trimmedTitle.isEmpty {
            result.append(
                CriterionDefinitionDto(
                    id: criterion.sourceId,
                    type: .bonusPenalty,
                    title: criterion.trimmedTitle,
                    orderIndex: index,
                    score: criterion.score,
                    direction: .subtract
                )
            )
            index += 1
        }

        for criterion in qualityCriteria where !criterion.trimmedTitle.isEmpty {
            result.append(
                CriterionDefinitionDto(
                    id: criterion.sourceId,
                    type: .quality,
                    title: criterion.trimmedTitle,
                    orderIndex: index,
                    threshold: normalizedPercent(criterion.threshold),
                    score: criterion.score,
                    direction: criterion.direction
                )
            )
            index += 1
        }

        for criterion in blockingCriteria where !criterion.trimmedTitle.isEmpty {
            result.append(
                CriterionDefinitionDto(
                    id: criterion.sourceId,
                    type: .blocking,
                    title: criterion.trimmedTitle,
                    orderIndex: index,
                    maxAllowedScore: criterion.maxAllowedScore
                )
            )
            index += 1
        }

        return result
    }

    private func normalizeWeights() {
        let sum = totalWeight
        guard sum > 0 else { return }
        for index in weightedCriteria.indices {
            weightedCriteria[index].weight = weightedCriteria[index].weight / sum
        }
    }

    private func formatScore(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }

    private func formatWeight(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...3)))
    }

    private func normalizedPercent(_ value: Double) -> Double {
        value / 100
    }

    private var minimumCriterionWeight: Double {
        0.05
    }
}

private enum ScoredCriterionCollection {
    case bonus
    case penalty
}

struct SpacedIntStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1

    var body: some View {
        HStack(spacing: 14) {
            Text(title)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 20)

            HStack(spacing: 34) {
                stepButton(systemImage: "minus.circle.fill", isDisabled: value <= range.lowerBound) {
                    value = max(range.lowerBound, value - step)
                }

                stepButton(systemImage: "plus.circle.fill", isDisabled: value >= range.upperBound) {
                    value = min(range.upperBound, value + step)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func stepButton(systemImage: String, isDisabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2)
                .frame(width: 46, height: 46)
                .contentShape(Rectangle())
                .foregroundStyle(isDisabled ? Color.secondary : Color.blue)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

struct SpacedDoubleStepper: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1

    var body: some View {
        HStack(spacing: 14) {
            Text(title)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 20)

            HStack(spacing: 34) {
                stepButton(systemImage: "minus.circle.fill", isDisabled: value <= range.lowerBound) {
                    value = max(range.lowerBound, value - step)
                }

                stepButton(systemImage: "plus.circle.fill", isDisabled: value >= range.upperBound) {
                    value = min(range.upperBound, value + step)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private func stepButton(systemImage: String, isDisabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2)
                .frame(width: 46, height: 46)
                .contentShape(Rectangle())
                .foregroundStyle(isDisabled ? Color.secondary : Color.blue)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

private struct WeightedCriterionDraft: Identifiable, Hashable {
    let id: UUID
    let sourceId: UUID?
    var title: String
    var maxScore: Double
    var weight: Double

    init(id: UUID = UUID(), sourceId: UUID? = nil, title: String, maxScore: Double, weight: Double) {
        self.id = id
        self.sourceId = sourceId
        self.title = title
        self.maxScore = maxScore
        self.weight = weight
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct ScoredCriterionDraft: Identifiable, Hashable {
    let id: UUID
    let sourceId: UUID?
    var title: String
    var score: Double

    init(id: UUID = UUID(), sourceId: UUID? = nil, title: String, score: Double) {
        self.id = id
        self.sourceId = sourceId
        self.title = title
        self.score = score
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct QualityCriterionDraft: Identifiable, Hashable {
    let id: UUID
    let sourceId: UUID?
    var title: String
    var threshold: Double
    var score: Double
    var direction: CriterionDirection

    init(
        id: UUID = UUID(),
        sourceId: UUID? = nil,
        title: String,
        threshold: Double,
        score: Double,
        direction: CriterionDirection
    ) {
        self.id = id
        self.sourceId = sourceId
        self.title = title
        self.threshold = threshold
        self.score = score
        self.direction = direction
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct BlockingCriterionDraft: Identifiable, Hashable {
    let id: UUID
    let sourceId: UUID?
    var title: String
    var maxAllowedScore: Double

    init(id: UUID = UUID(), sourceId: UUID? = nil, title: String, maxAllowedScore: Double) {
        self.id = id
        self.sourceId = sourceId
        self.title = title
        self.maxAllowedScore = maxAllowedScore
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
