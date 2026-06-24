
import SwiftUI
import UniformTypeIdentifiers

struct PostDetailView: View {
    @StateObject private var vm: PostDetailViewModel
    @State private var commentText = ""
    @State private var showSolution = false
    @State private var showTeamSolution = false
    @State private var showEditPost = false
    @FocusState private var commentFocused: Bool

    let title: String
    let role: UserRoleType
    let onPostChanged: (() -> Void)?

    init(postId: UUID, courseId: UUID, title: String, role: UserRoleType, onPostChanged: (() -> Void)? = nil) {
        _vm = StateObject(wrappedValue: PostDetailViewModel(postId: postId, courseId: courseId))
        self.title = title
        self.role = role
        self.onPostChanged = onPostChanged
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                if let post = vm.post {
                    PostBodyView(post: post)

                    // Regular task actions
                    if post.type == .task {
                        if role == .student {
                            Button {
                                showSolution = true
                            } label: {
                                Label("Моё решение", systemImage: "tray.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.blue)
                                    .foregroundStyle(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        } else {
                            teacherTaskReviewAction(post: post)
                        }
                    }

                    // Team task actions
                    if post.type == .teamTask {
                        VStack(spacing: 10) {
                            NavigationLink {
                                TeamTaskView(
                                    assignmentId: vm.postId,
                                    role: role,
                                    taskTitle: post.title,
                                    maxScore: post.maxScore
                                )
                            } label: {
                                Label("Команды", systemImage: "person.3.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundStyle(.blue)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)

                            if role == .student {
                                Button {
                                    showTeamSolution = true
                                } label: {
                                    Label("Командное решение", systemImage: "tray.and.arrow.up")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(.blue)
                                        .foregroundStyle(.white)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)
                            } else {
                                teacherTeamReviewAction(post: post)
                            }
                        }
                    }
                } else if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                }

                Divider().padding(.horizontal)

                Text("Комментарии (\(vm.comments.count))")
                    .font(.headline)
                    .padding(.horizontal)

                ForEach(vm.comments, id: \.id) { comment in
                    CommentRowView(comment: comment) {
                        Task { await vm.deleteComment(comment.id) }
                    }
                }

                
                VStack(spacing: 8) {
                    if let error = vm.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                    HStack(spacing: 8) {
                        TextField("Написать комментарий…", text: $commentText, axis: .vertical)
                            .lineLimit(1...4)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .focused($commentFocused)
                        Button {
                            let text = commentText
                            commentText = ""
                            commentFocused = false
                            Task { await vm.addComment(text: text) }
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .foregroundStyle(.blue)
                        }
                        .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty || vm.isSendingComment)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
        .navigationTitle(vm.post?.title ?? title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if canEditPost {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEditPost = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $showSolution) {
            if let post = vm.post {
                SolutionView(
                    taskId: vm.postId,
                    maxScore: post.maxScore,
                    criteria: post.criteria ?? [],
                    selfAssessmentEnabled: (post.studentScoreWeight ?? 0) > 0
                )
            }
        }
        .sheet(isPresented: $showTeamSolution) {
            if let post = vm.post {
                TeamSolutionView(
                    taskId: vm.postId,
                    maxScore: post.maxScore,
                    criteria: post.criteria ?? [],
                    selfAssessmentEnabled: (post.studentScoreWeight ?? 0) > 0
                )
            }
        }
        .sheet(isPresented: $showEditPost) {
            if let post = vm.post {
                CreatePostView(courseId: vm.courseId, editingPost: post) {
                    Task {
                        await vm.load()
                        onPostChanged?()
                    }
                }
            }
        }
        .task { await vm.load() }
    }

    private var canEditPost: Bool {
        guard role == .teacher, let post = vm.post else { return false }
        return post.type == .task || post.type == .teamTask
    }

    @ViewBuilder
    private func teacherTaskReviewAction(post: PostDetailsDto) -> some View {
        if (post.gradingMode ?? .teacherReview) == .teacherReview {
            NavigationLink {
                ReviewSolutionView(taskId: vm.postId, maxScore: post.maxScore, criteria: post.criteria ?? [])
            } label: {
                Label("Решения студентов", systemImage: "person.text.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        } else {
            peerReviewLockedNotice(
                title: "Проверка преподавателем отключена",
                subtitle: "Это P2P-задание: работа засчитывается после сдачи решения и минимального числа оценок от студента."
            )
        }
    }

    @ViewBuilder
    private func teacherTeamReviewAction(post: PostDetailsDto) -> some View {
        if (post.gradingMode ?? .teacherReview) == .teacherReview {
            NavigationLink {
                ReviewTeamSolutionView(taskId: vm.postId, maxScore: post.maxScore, criteria: post.criteria ?? [])
            } label: {
                Label("Решения команд", systemImage: "person.text.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        } else {
            peerReviewLockedNotice(
                title: "Проверка команд преподавателем отключена",
                subtitle: "Это P2P-задание: студенту нужно оценить работу хотя бы одной другой команды."
            )
        }
    }

    private func peerReviewLockedNotice(title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.2.wave.2.fill")
                .foregroundStyle(.indigo)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color.indigo.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

private struct PostBodyView: View {
    let post: PostDetailsDto
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: typeIcon)
                    .foregroundStyle(typeColor)
                Text(typeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let deadline = post.deadline {
                    Label(deadline.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Text(post.title)
                .font(.title2.bold())
            if !post.text.isEmpty {
                Text(post.text)
                    .font(.body)
            }
            if let maxScore = post.maxScore {
                HStack {
                    Image(systemName: "star.fill").foregroundStyle(.yellow)
                    Text("Максимум: \(maxScore) баллов")
                        .font(.subheadline)
                }
            }
            if post.type == .task || post.type == .teamTask {
                gradingModeBadge
            }
            if let criteria = post.criteria, !criteria.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Label("\(criteria.count) критериев оценивания", systemImage: "list.bullet.clipboard")
                        .font(.subheadline)
                    Text("Макс. по критериям: \(formatScore(CriterionCalculator.maxScore(criteria: criteria)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if hasAdvancedGrading {
                VStack(alignment: .leading, spacing: 4) {
                    if let failThreshold = post.failThreshold {
                        Label("Незачёт ниже \(formatPercent(failThreshold))%", systemImage: "exclamationmark.triangle")
                    }
                    if let successThreshold = post.successThreshold {
                        Label("Максимум от \(formatPercent(successThreshold))%", systemImage: "checkmark.seal")
                    }
                    if let weight = post.studentScoreWeight {
                        Label("Вес самооценки: \(formatScore(weight))", systemImage: "person.crop.circle.badge.checkmark")
                    }
                    if let penalty = post.penaltyPerDay {
                        Label("Просрочка: −\(formatScore(penalty))/день", systemImage: "clock.badge.exclamationmark")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            if let files = post.files, !files.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Файлы:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(files, id: \.id) { file in
                        PostFileRowView(file: file)
                    }
                }
            }
            if let solution = post.userSolution {
                SolutionBadgeView(solution: solution)
            }
        }
        .padding()
    }

    private var hasAdvancedGrading: Bool {
        post.failThreshold != nil ||
        post.successThreshold != nil ||
        post.studentScoreWeight != nil ||
        post.penaltyPerDay != nil
    }

    private var gradingModeBadge: some View {
        let mode = post.gradingMode ?? .teacherReview
        return HStack(spacing: 8) {
            Image(systemName: mode == .peerToPeer ? "person.2.wave.2.fill" : "person.text.rectangle")
                .foregroundStyle(mode == .peerToPeer ? .indigo : .orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(mode == .peerToPeer ? "P2P-оценивание" : "Проверяет преподаватель")
                    .font(.subheadline.bold())
                if mode == .peerToPeer {
                    Text(post.type == .task ? "Минимум оцениваний: \(post.minPeerReviewsRequired ?? 1)" : "Нужно оценить одну другую команду")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background((mode == .peerToPeer ? Color.indigo : Color.orange).opacity(0.1))
        .cornerRadius(10)
    }

    private var typeIcon: String {
        switch post.type {
        case .task: return "checkmark.circle.fill"
        case .teamTask: return "person.3.fill"
        case .post: return "doc.text.fill"
        }
    }

    private var typeColor: Color {
        switch post.type {
        case .task: return .orange
        case .teamTask: return .purple
        case .post: return .blue
        }
    }

    private var typeText: String {
        switch post.type {
        case .task: return "Задание"
        case .teamTask: return "Командное задание"
        case .post: return "Пост"
        }
    }

    private func formatScore(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }

    private func formatPercent(_ value: Double) -> String {
        formatScore(value > 1 ? value : value * 100)
    }
}

private struct SolutionBadgeView: View {
    let solution: UserSolutionDto
    var body: some View {
        HStack {
            Image(systemName: statusIcon).foregroundStyle(statusColor)
            Text(statusText).font(.subheadline.bold()).foregroundStyle(statusColor)
            Spacer()
            if solution.score > 0 {
                Text("\(solution.score) баллов").font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(statusColor.opacity(0.1))
        .cornerRadius(8)
    }
    private var statusIcon: String {
        switch solution.status {
        case .pending: return "clock.fill"
        case .checked: return "checkmark.circle.fill"
        case .returned: return "arrow.uturn.left.circle.fill"
        case .none: return "questionmark.circle"
        }
    }
    private var statusColor: Color {
        switch solution.status {
        case .pending: return .orange
        case .checked: return .green
        case .returned: return .red
        case .none: return .gray
        }
    }
    private var statusText: String {
        switch solution.status {
        case .pending: return "На проверке"
        case .checked: return "Проверено"
        case .returned: return "Возвращено"
        case .none: return "Не сдано"
        }
    }
}

private struct PostFileRowView: View {
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
            }
        } else {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundStyle(.secondary)
                Text(file.name ?? "Файл")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct CommentRowView: View {
    let comment: CommentDto
    let onDelete: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(comment.author.credentials).font(.caption.bold())
                Spacer()
                if !comment.isDeleted {
                    Button(role: .destructive) { onDelete() } label: {
                        Image(systemName: "trash").font(.caption).foregroundStyle(.red)
                    }
                }
            }
            Text(comment.isDeleted ? "Комментарий удалён" : comment.text)
                .font(.subheadline)
                .foregroundStyle(comment.isDeleted ? .secondary : .primary)
                .italic(comment.isDeleted)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}
