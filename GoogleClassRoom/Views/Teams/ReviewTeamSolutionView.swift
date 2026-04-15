import SwiftUI

struct ReviewTeamSolutionView: View {

    @StateObject private var vm: ReviewTeamSolutionViewModel

    init(taskId: UUID, maxScore: Int?) {
        _vm = StateObject(wrappedValue: ReviewTeamSolutionViewModel(taskId: taskId, maxScore: maxScore))
    }

    var body: some View {
        Group {
            if vm.isLoading && vm.solutions.isEmpty {
                ProgressView("Загрузка решений команд…")
            } else if vm.solutions.isEmpty {
                ContentUnavailableView(
                    "Нет решений",
                    systemImage: "tray",
                    description: Text("Команды ещё не сдали работы")
                )
            } else {
                List(vm.solutions) { solution in
                    NavigationLink {
                        TeamSolutionReviewDetailView(solution: solution, vm: vm)
                    } label: {
                        TeamSolutionRowView(solution: solution)
                    }
                }
                .refreshable { await vm.loadSolutions() }
            }
        }
        .navigationTitle("Решения команд")
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

private struct TeamSolutionRowView: View {
    let solution: TeamSolutionListItemDto

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(solution.team.name)
                    .font(.headline)
                Text("\(solution.team.members.count) участников · \(statusText)")
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

private struct TeamSolutionReviewDetailView: View {
    let solution: TeamSolutionListItemDto
    @ObservedObject var vm: ReviewTeamSolutionViewModel

    @State private var scoreText = ""
    @State private var comment = ""
    @State private var selectedStatus: SolutionStatus = .checked
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Team info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.3.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text(solution.team.name)
                                .font(.headline)
                            Text(solution.updatedDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    // Members
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(solution.team.members, id: \.userId) { member in
                            HStack(spacing: 4) {
                                Image(systemName: member.role == .leader ? "crown.fill" : "person.fill")
                                    .font(.caption2)
                                    .foregroundStyle(member.role == .leader ? .yellow : .secondary)
                                Text(member.credentials)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal)
                }

                if !solution.text.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ответ команды:")
                            .font(.caption).foregroundStyle(.secondary).padding(.horizontal)
                        Text(solution.text)
                            .font(.body).padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6)).cornerRadius(10).padding(.horizontal)
                    }
                }

                if let files = solution.files, !files.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Прикреплённые файлы:")
                            .font(.caption).foregroundStyle(.secondary).padding(.horizontal)
                        ForEach(files, id: \.id) { file in
                            reviewFileRow(file: file)
                        }
                    }
                }

                Divider().padding(.horizontal)

                // Review form
                VStack(alignment: .leading, spacing: 12) {
                    Text("Оценка").font(.headline).padding(.horizontal)

                    Picker("Статус", selection: $selectedStatus) {
                        Text("Принято").tag(SolutionStatus.checked)
                        Text("Вернуть").tag(SolutionStatus.returned)
                    }
                    .pickerStyle(.segmented).padding(.horizontal)

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

                    TextField("Комментарий (необязательно)", text: $comment, axis: .vertical)
                        .lineLimit(2...5).padding()
                        .background(Color(.systemGray6)).cornerRadius(10).padding(.horizontal)
                }

                if let error = vm.errorMessage {
                    Text(error).foregroundStyle(.red).font(.caption).padding(.horizontal)
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
                        if vm.isReviewing { ProgressView() }
                        else { Text("Сохранить проверку").font(.headline) }
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(.blue).foregroundStyle(.white).cornerRadius(12)
                }
                .disabled(vm.isReviewing).padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationTitle("Проверка команды")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let score = solution.score { scoreText = "\(score)" }
            selectedStatus = solution.status
        }
    }

    private func reviewFileRow(file: FileDto) -> some View {
        Group {
            if let idStr = file.id, let uuid = UUID(uuidString: idStr),
               let url = URL(string: "\(APIClient.baseURL)/api/files/\(uuid.uuidString)") {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "doc.fill").foregroundStyle(.orange)
                        Text(file.name ?? "Файл").font(.subheadline).lineLimit(1).foregroundStyle(.orange)
                        Spacer()
                        Image(systemName: "arrow.down.circle").foregroundStyle(.orange)
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
}
