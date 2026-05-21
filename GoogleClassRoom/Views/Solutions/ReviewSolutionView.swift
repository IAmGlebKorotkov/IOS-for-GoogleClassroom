import SwiftUI

struct ReviewSolutionView: View {

    @StateObject private var vm: ReviewSolutionViewModel

    init(taskId: UUID, maxScore: Int?, criteria: [CriterionDto] = []) {
        _vm = StateObject(wrappedValue: ReviewSolutionViewModel(taskId: taskId, maxScore: maxScore, criteria: criteria))
    }

    var body: some View {
        Group {
            if vm.isLoading && vm.solutions.isEmpty {
                ProgressView("Загрузка решений…")
            } else if vm.solutions.isEmpty {
                ContentUnavailableView(
                    "Нет решений",
                    systemImage: "tray",
                    description: Text("Студенты ещё не сдали работы")
                )
            } else {
                List(vm.solutions, id: \.id) { solution in
                    NavigationLink {
                        SolutionReviewDetailView(solution: solution, vm: vm)
                    } label: {
                        SolutionListRowView(solution: solution)
                    }
                }
                .refreshable { await vm.loadSolutions() }
            }
        }
        .navigationTitle("Решения студентов")
        .alert("Ошибка", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .alert("Готово", isPresented: .constant(vm.successMessage != nil)) {
            Button("OK") { vm.successMessage = nil }
        } message: {
            Text(vm.successMessage ?? "")
        }
        .task { await vm.loadSolutions() }
    }
}

private struct SolutionListRowView: View {
    let solution: SolutionListItemDto

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(solution.user.credentials)
                    .font(.headline)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let score = solution.score {
                Text("\(score)")
                    .font(.title3.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch solution.status {
        case .pending: return .orange
        case .checked: return .green
        case .returned: return .red
        }
    }

    private var statusText: String {
        switch solution.status {
        case .pending: return "Ожидает проверки"
        case .checked: return "Проверено"
        case .returned: return "Возвращено"
        }
    }
}

private struct SolutionReviewDetailView: View {

    let solution: SolutionListItemDto
    @ObservedObject var vm: ReviewSolutionViewModel

    @State private var scoreText = ""
    @State private var comment = ""
    @State private var selectedStatus: SolutionStatus = .checked
    @State private var weightedScores: [UUID: Double] = [:]
    @State private var enabledCriteria: Set<UUID> = []
    @State private var previewTask: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text(solution.user.credentials)
                            .font(.headline)
                        Text(solution.updatedDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                if !solution.text.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ответ студента:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        Text(solution.text)
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
                        Text("Прикреплённые файлы студента:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        ForEach(files, id: \.id) { file in
                            ReviewFileRowView(file: file)
                        }
                    }
                }

                Divider().padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Оценка")
                        .font(.headline)
                        .padding(.horizontal)

                    Picker("Статус", selection: $selectedStatus) {
                        Text("Принято").tag(SolutionStatus.checked)
                        Text("Вернуть на доработку").tag(SolutionStatus.returned)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if selectedStatus == .checked {
                        if usesCriteria {
                            CriteriaEvaluationView(
                                criteria: vm.criteria,
                                weightedScores: $weightedScores,
                                enabledCriteria: $enabledCriteria
                            )
                            .padding(.horizontal)

                            GradeBreakdownCard(
                                breakdown: vm.previewBreakdown,
                                estimatedScore: estimatedScore,
                                isLoading: vm.isPreviewing
                            )
                            .padding(.horizontal)
                        } else if let max = vm.maxScore {
                            HStack {
                                Text("Баллы (0–\(max)):")
                                TextField("0", text: $scoreText)
                                    .keyboardType(.numberPad)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .frame(width: 80)
                            }
                            .padding(.horizontal)
                        }
                    }

                    TextField("Комментарий к решению (необязательно)", text: $comment, axis: .vertical)
                        .lineLimit(2...5)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                Button {
                    let evaluation = selectedStatus == .checked && usesCriteria ? currentEvaluation : nil
                    let score: Int? = {
                        guard selectedStatus == .checked else { return nil }
                        if usesCriteria {
                            return Int((vm.previewBreakdown?.finalScore ?? estimatedScore).rounded())
                        }
                        return Int(scoreText)
                    }()
                    Task {
                        await vm.review(
                            solutionId: solution.id,
                            score: score,
                            status: selectedStatus,
                            comment: comment.isEmpty ? nil : comment,
                            evaluation: evaluation
                        )
                        if vm.errorMessage == nil { dismiss() }
                    }
                } label: {
                    Group {
                        if vm.isReviewing {
                            ProgressView()
                        } else {
                            Text("Сохранить проверку")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .disabled(vm.isReviewing)
                .padding(.horizontal)

                Divider().padding(.horizontal)

                SolutionCommentsView(solutionId: solution.id)
                    .padding(.bottom)
            }
            .padding(.top)
        }
        .navigationTitle("Проверка решения")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let score = solution.score { scoreText = "\(score)" }
            selectedStatus = solution.status
            resetCriteriaState()
            schedulePreview()
        }
        .onChange(of: weightedScores) {
            schedulePreview()
        }
        .onChange(of: enabledCriteria) {
            schedulePreview()
        }
        .onChange(of: selectedStatus) {
            schedulePreview()
        }
        .onDisappear {
            previewTask?.cancel()
        }
    }

    private var usesCriteria: Bool {
        !vm.criteria.isEmpty
    }

    private var currentEvaluation: EvaluationDto {
        CriterionCalculator.makeEvaluation(
            criteria: vm.criteria,
            weightedScores: weightedScores,
            toggledCriteria: enabledCriteria
        )
    }

    private var estimatedScore: Double {
        CriterionCalculator.estimatedScore(criteria: vm.criteria, evaluation: currentEvaluation)
    }

    private func resetCriteriaState() {
        guard usesCriteria else { return }
        vm.previewBreakdown = nil
        var scores: [UUID: Double] = [:]
        for criterion in vm.criteria where criterion.type == .weighted {
            scores[criterion.id] = 0
        }
        weightedScores = scores
        enabledCriteria = Set(vm.criteria.filter { $0.type == .quality }.map(\.id))
    }

    private func schedulePreview() {
        guard usesCriteria, selectedStatus == .checked else { return }
        let evaluation = currentEvaluation
        previewTask?.cancel()
        previewTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await vm.preview(solutionId: solution.id, evaluation: evaluation)
        }
    }
}

private struct ReviewFileRowView: View {
    let file: FileDto

    var body: some View {
        if let idString = file.id,
           let uuid = UUID(uuidString: idString),
           let url = URL(string: "\(APIClient.baseURL)/api/files/\(uuid.uuidString)") {
            Link(destination: url) {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(.orange)
                    Text(file.name ?? "Файл")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "arrow.down.circle")
                        .foregroundStyle(.orange)
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

struct CriteriaEvaluationView: View {
    let criteria: [CriterionDto]
    @Binding var weightedScores: [UUID: Double]
    @Binding var enabledCriteria: Set<UUID>

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !weightedCriteria.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Весовые критерии", systemImage: "slider.horizontal.3")
                        .font(.subheadline.bold())
                    ForEach(weightedCriteria) { criterion in
                        weightedCriterionRow(criterion)
                    }
                }
            }

            if !bonusCriteria.isEmpty {
                toggleGroup(title: "Бонусы", icon: "plus.circle.fill", color: .green, items: bonusCriteria)
            }

            if !penaltyCriteria.isEmpty {
                toggleGroup(title: "Штрафы", icon: "minus.circle.fill", color: .red, items: penaltyCriteria)
            }

            if !advancedCriteria.isEmpty {
                toggleGroup(title: "Расширенные", icon: "exclamationmark.shield.fill", color: .purple, items: advancedCriteria)
            }
        }
    }

    private var sortedCriteria: [CriterionDto] {
        criteria.sorted { $0.orderIndex < $1.orderIndex }
    }

    private var weightedCriteria: [CriterionDto] {
        sortedCriteria.filter { $0.type == .weighted }
    }

    private var bonusCriteria: [CriterionDto] {
        sortedCriteria.filter { $0.type == .bonusPenalty && $0.direction == .add }
    }

    private var penaltyCriteria: [CriterionDto] {
        sortedCriteria.filter { $0.type == .bonusPenalty && $0.direction == .subtract }
    }

    private var advancedCriteria: [CriterionDto] {
        sortedCriteria.filter { $0.type == .quality || $0.type == .blocking }
    }

    private func weightedCriterionRow(_ criterion: CriterionDto) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(criterion.title ?? "Критерий")
                        .font(.subheadline)
                    Text("вес ×\(format(criterion.weight ?? 1)) · макс. \(format(criterion.maxScore ?? 0))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(format(weightedScores[criterion.id] ?? 0))
                    .font(.headline)
                    .monospacedDigit()
            }

            Slider(
                value: Binding(
                    get: { weightedScores[criterion.id] ?? 0 },
                    set: { weightedScores[criterion.id] = min(max($0, 0), criterion.maxScore ?? 0) }
                ),
                in: 0...(criterion.maxScore ?? 0),
                step: 0.5
            )

            SpacedDoubleStepper(
                title: "Вклад: \(format((weightedScores[criterion.id] ?? 0) * (criterion.weight ?? 1)))",
                value: Binding(
                    get: { weightedScores[criterion.id] ?? 0 },
                    set: { weightedScores[criterion.id] = min(max($0, 0), criterion.maxScore ?? 0) }
                ),
                range: 0...(criterion.maxScore ?? 0),
                step: 0.5
            )
            .font(.caption)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    private func toggleGroup(title: String, icon: String, color: Color, items: [CriterionDto]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundStyle(color)
            ForEach(items) { criterion in
                Toggle(isOn: Binding(
                    get: { enabledCriteria.contains(criterion.id) },
                    set: { enabled in
                        if enabled {
                            enabledCriteria.insert(criterion.id)
                        } else {
                            enabledCriteria.remove(criterion.id)
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(criterion.title ?? "Критерий")
                            .font(.subheadline)
                        Text(criterionDescription(criterion))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }

    private func criterionDescription(_ criterion: CriterionDto) -> String {
        switch criterion.type {
        case .weighted:
            return "макс. \(format(criterion.maxScore ?? 0)) · вес \(format(criterion.weight ?? 1))"
        case .bonusPenalty:
            let sign = criterion.direction == .subtract ? "−" : "+"
            return "\(sign)\(format(criterion.score ?? 0)) балл."
        case .quality:
            let sign = criterion.direction == .subtract ? "−" : "+"
            let relation = criterion.direction == .subtract ? "ниже" : "выше"
            return "\(sign)\(format(criterion.score ?? 0)) при \(relation) \(formatPercent(criterion.threshold ?? 0))%"
        case .blocking:
            return "итог не выше \(format(criterion.maxAllowedScore ?? 0))"
        }
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }

    private func formatPercent(_ value: Double) -> String {
        format(value > 1 ? value : value * 100)
    }
}

struct GradeBreakdownCard: View {
    let breakdown: GradeBreakdownDto?
    let estimatedScore: Double
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Итоговая оценка", systemImage: "sum")
                    .font(.headline)
                Spacer()
                if isLoading {
                    ProgressView()
                }
            }

            Text(format(breakdown?.finalScore ?? estimatedScore))
                .font(.largeTitle.bold())
                .monospacedDigit()

            if let breakdown {
                VStack(alignment: .leading, spacing: 4) {
                    breakdownLine("База", breakdown.baseScore)
                    breakdownLine("После качества", breakdown.afterQualityCoefficient)
                    if breakdown.latePenalty > 0 {
                        breakdownLine("Штраф за просрочку", -breakdown.latePenalty)
                    }
                    breakdownLine("После блокировок", breakdown.afterBlocking)
                    if breakdown.thresholdApplied, let reason = breakdown.thresholdReason {
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            } else {
                Text("Локальный предварительный расчёт")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private func breakdownLine(_ title: String, _ value: Double) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(format(value))
                .monospacedDigit()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }
}
