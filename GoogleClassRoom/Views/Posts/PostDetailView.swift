
import SwiftUI
import UniformTypeIdentifiers

struct PostDetailView: View {
    @StateObject private var vm: PostDetailViewModel
    @State private var commentText = ""
    @State private var showSolution = false
    @State private var showTeamSolution = false
    @FocusState private var commentFocused: Bool

    let title: String
    let role: UserRoleType

    init(postId: UUID, courseId: UUID, title: String, role: UserRoleType) {
        _vm = StateObject(wrappedValue: PostDetailViewModel(postId: postId, courseId: courseId))
        self.title = title
        self.role = role
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
                            NavigationLink {
                                ReviewSolutionView(taskId: vm.postId, maxScore: post.maxScore)
                            } label: {
                                Label("Решения студентов", systemImage: "person.text.rectangle")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.orange)
                                    .foregroundStyle(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
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
                                NavigationLink {
                                    ReviewTeamSolutionView(taskId: vm.postId, maxScore: post.maxScore)
                                } label: {
                                    Label("Решения команд", systemImage: "person.text.rectangle")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(.orange)
                                        .foregroundStyle(.white)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)
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
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSolution) {
            if let post = vm.post {
                SolutionView(taskId: vm.postId, maxScore: post.maxScore)
            }
        }
        .sheet(isPresented: $showTeamSolution) {
            if let post = vm.post {
                TeamSolutionView(taskId: vm.postId, maxScore: post.maxScore)
            }
        }
        .task { await vm.load() }
    }
}

private struct PostBodyView: View {
    let post: PostDetailsDto
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: post.type == .task ? "checkmark.circle.fill" : "doc.text.fill")
                    .foregroundStyle(post.type == .task ? .orange : .blue)
                Text(post.type == .task ? "Задание" : "Пост")
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
