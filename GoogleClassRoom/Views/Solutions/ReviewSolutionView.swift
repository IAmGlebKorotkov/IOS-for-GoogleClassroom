import SwiftUI

struct ReviewSolutionView: View {

    @StateObject private var vm: ReviewSolutionViewModel

    init(taskId: UUID, maxScore: Int?) {
        _vm = StateObject(wrappedValue: ReviewSolutionViewModel(taskId: taskId, maxScore: maxScore))
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

                    if selectedStatus == .checked, let max = vm.maxScore {
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
                    let score = Int(scoreText)
                    Task {
                        await vm.review(
                            solutionId: solution.id,
                            score: score,
                            status: selectedStatus,
                            comment: comment.isEmpty ? nil : comment
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
