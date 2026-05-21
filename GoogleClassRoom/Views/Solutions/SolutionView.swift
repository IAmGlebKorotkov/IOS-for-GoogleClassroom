import SwiftUI
import UniformTypeIdentifiers

struct SolutionView: View {

    @StateObject private var vm: SolutionViewModel
    @Environment(\.dismiss) private var dismiss
    private let criteria: [CriterionDto]
    private let selfAssessmentEnabled: Bool

    @State private var solutionText = ""
    @State private var showFilePicker = false
    @State private var selfWeightedScores: [UUID: Double] = [:]
    @State private var selfEnabledCriteria: Set<UUID> = []
    @State private var selfPreviewTask: Task<Void, Never>?

    init(
        taskId: UUID,
        maxScore: Int?,
        criteria: [CriterionDto] = [],
        selfAssessmentEnabled: Bool = false
    ) {
        self.criteria = criteria.sorted { $0.orderIndex < $1.orderIndex }
        self.selfAssessmentEnabled = selfAssessmentEnabled
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
                        selfAssessmentSection(solution: solution)

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
        .onDisappear {
            selfPreviewTask?.cancel()
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

            if let breakdown = solution.breakdown {
                GradeBreakdownCard(
                    breakdown: breakdown,
                    estimatedScore: Double(solution.score ?? 0),
                    isLoading: false
                )
                .padding(.horizontal)
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

    @ViewBuilder
    private func selfAssessmentSection(solution: StudentSolutionDetailsDto) -> some View {
        if !criteria.isEmpty, selfAssessmentEnabled {
            VStack(alignment: .leading, spacing: 12) {
                Divider().padding(.horizontal)

                Text("Самооценка по критериям")
                    .font(.headline)
                    .padding(.horizontal)

                if let selfAssessment = solution.selfAssessment, !selfAssessment.isEmpty {
                    HStack {
                        Label("Сохранена", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Spacer()
                        Text(formatScore(CriterionCalculator.estimatedScore(criteria: criteria, evaluation: selfAssessment)))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    .padding(.horizontal)
                }

                CriteriaEvaluationView(
                    criteria: criteria,
                    weightedScores: $selfWeightedScores,
                    enabledCriteria: $selfEnabledCriteria
                )
                .padding(.horizontal)

                GradeBreakdownCard(
                    breakdown: vm.selfAssessmentPreview,
                    estimatedScore: selfAssessmentEstimatedScore,
                    isLoading: vm.isPreviewingSelfAssessment
                )
                .padding(.horizontal)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        saveSelfAssessmentButton
                        deleteSelfAssessmentButton
                    }

                    VStack(spacing: 10) {
                        saveSelfAssessmentButton
                        deleteSelfAssessmentButton
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                resetSelfAssessmentState(evaluation: solution.selfAssessment)
                scheduleSelfAssessmentPreview(solution: solution)
            }
            .onChange(of: selfWeightedScores) {
                scheduleSelfAssessmentPreview(solution: solution)
            }
            .onChange(of: selfEnabledCriteria) {
                scheduleSelfAssessmentPreview(solution: solution)
            }
        } else if !criteria.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Divider().padding(.horizontal)
                Label("Самооценка отключена для этого задания", systemImage: "person.crop.circle.badge.xmark")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
    }

    private var saveSelfAssessmentButton: some View {
        Button {
            Task { await vm.submitSelfAssessment(evaluation: selfAssessmentEvaluation) }
        } label: {
            Label("Сохранить самооценку", systemImage: "checkmark.circle.fill")
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.green)
                .foregroundStyle(.white)
                .cornerRadius(12)
        }
        .disabled(vm.isSubmittingSelfAssessment)
    }

    private var deleteSelfAssessmentButton: some View {
        Button(role: .destructive) {
            Task {
                await vm.deleteSelfAssessment()
                resetSelfAssessmentState(evaluation: nil, force: true)
            }
        } label: {
            Label("Удалить", systemImage: "trash")
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundStyle(.red)
                .cornerRadius(12)
        }
        .disabled(vm.isSubmittingSelfAssessment)
    }

    private var selfAssessmentEvaluation: EvaluationDto {
        CriterionCalculator.makeEvaluation(
            criteria: criteria,
            weightedScores: selfWeightedScores,
            toggledCriteria: selfEnabledCriteria
        )
    }

    private var selfAssessmentEstimatedScore: Double {
        CriterionCalculator.estimatedScore(criteria: criteria, evaluation: selfAssessmentEvaluation)
    }

    private func resetSelfAssessmentState(evaluation: EvaluationDto?, force: Bool = false) {
        guard !criteria.isEmpty, force || selfWeightedScores.isEmpty else { return }

        let weightedById = Dictionary(
            uniqueKeysWithValues: (evaluation?.weightedValues ?? []).map { ($0.criterionId, $0.score) }
        )
        var scores: [UUID: Double] = [:]
        for criterion in criteria where criterion.type == .weighted {
            scores[criterion.id] = weightedById[criterion.id] ?? 0
        }
        selfWeightedScores = scores

        if let evaluation {
            selfEnabledCriteria = Set((evaluation.toggledValues ?? []).filter { $0.enabled }.map(\.criterionId))
        } else {
            selfEnabledCriteria = Set(criteria.filter { $0.type == .quality }.map(\.id))
        }
    }

    private func scheduleSelfAssessmentPreview(solution: StudentSolutionDetailsDto) {
        guard let solutionId = solution.id, !criteria.isEmpty else { return }
        let evaluation = selfAssessmentEvaluation
        selfPreviewTask?.cancel()
        selfPreviewTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await vm.previewSelfAssessment(solutionId: solutionId, evaluation: evaluation)
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

    private func formatScore(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
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
